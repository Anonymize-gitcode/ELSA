pragma solidity ^0.8.21;

interface ISemaphoreVerifier {

    function verifyProof(uint256[8] calldata proof, uint256[4] calldata input) external view;

    function verifyCompressedProof(uint256[4] calldata compressedProof, uint256[4] calldata input)
        external
        view;
}

contract SemaphoreVerifier is ISemaphoreVerifier {

    error PublicInputNotInField();

    error ProofInvalid();

    uint256 constant PRECOMPILE_MODEXP = 0x05;
    uint256 constant PRECOMPILE_ADD = 0x06;
    uint256 constant PRECOMPILE_MUL = 0x07;
    uint256 constant PRECOMPILE_VERIFY = 0x08;

    uint256 constant P = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 constant R = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    uint256 constant FRACTION_1_2_FP =
        0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea4;
    uint256 constant FRACTION_27_82_FP =
        0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 constant FRACTION_3_82_FP =
        0x2fcd3ac2a640a154eb23960892a85a68f031ca0c8344b23a577dcf1052b9e775;

    uint256 constant EXP_INVERSE_FP =
        0x30644E72E131A029B85045B68181585D97816A916871CA8D3C208C16D87CFD45;
    uint256 constant EXP_SQRT_FP = 0xC19139CB84C680A6E14116DA060561765E05AA45A1C72A34F082305B61F3F52;

    uint256 constant ALPHA_X =
        20491192805390485299153009773594534940189261866228447918068658471970481763042;
    uint256 constant ALPHA_Y =
        9383485363053290200918347156157836566562967994039712273449902621266178545958;

    uint256 constant BETA_NEG_X_0 =
        6375614351688725206403948262868962793625744043794305715222011528459656738731;
    uint256 constant BETA_NEG_X_1 =
        4252822878758300859123897981450591353533073413197771768651442665752259397132;
    uint256 constant BETA_NEG_Y_0 =
        11383000245469012944693504663162918391286475477077232690815866754273895001727;
    uint256 constant BETA_NEG_Y_1 =
        41207766310529818958173054109690360505148424997958324311878202295167071904;

    uint256 constant GAMMA_NEG_X_0 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant GAMMA_NEG_X_1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant GAMMA_NEG_Y_0 =
        13392588948715843804641432497768002650278120570034223513918757245338268106653;
    uint256 constant GAMMA_NEG_Y_1 =
        17805874995975841540914202342111839520379459829704422454583296818431106115052;

    uint256 constant DELTA_NEG_X_0 =
        15028154694713144242204861571552635520290993855826554325002991692907421516918;
    uint256 constant DELTA_NEG_X_1 =
        10202326166286888893675634318107715186834588694714750762952081034135561546271;
    uint256 constant DELTA_NEG_Y_0 =
        9121952986466441409625823112409402110610350380222160673756836983949377617226;
    uint256 constant DELTA_NEG_Y_1 =
        3402203030459169245973828223647408421795734658790470725360311404592929738724;

    uint256 constant CONSTANT_X =
        1452272927738590248356371174422184656932731110936062990115610832462181634644;
    uint256 constant CONSTANT_Y =
        3608050114233210789542189629343107890943266759827387991788718454179833288695;
    uint256 constant PUB_0_X =
        14798240452388909327945424685903532333765637883272751382037716636327236955001;
    uint256 constant PUB_0_Y =
        10773894897711848209682368488916121016695006898681985691467605219098835500201;
    uint256 constant PUB_1_X =
        17204267933132009093604099819536245144503489322639121825381131096467570698650;
    uint256 constant PUB_1_Y =
        7704298975420304156332734115679983371345754866278811368869074990486717531131;
    uint256 constant PUB_2_X =
        8060465662017324080560848316478407038163145149983639907596180500095598669247;
    uint256 constant PUB_2_Y =
        20475082166427284188002500222093571716651248980245637602667562336751029856573;
    uint256 constant PUB_3_X =
        7457566682692308112726332096733260585025339741083447785327706250123165087868;
    uint256 constant PUB_3_Y =
        11904519443874922292602150685069370036383697877657723976244907400392778002614;

    function negate(uint256 a) internal pure returns (uint256 x) {
        unchecked {
            x = (P - (a % P)) % P;
        }
    }

    function exp(uint256 a, uint256 e) internal view returns (uint256 x) {
        bool success;
        assembly ("memory-safe") {
            let f := mload(0x40)
            mstore(f, 0x20)
            mstore(add(f, 0x20), 0x20)
            mstore(add(f, 0x40), 0x20)
            mstore(add(f, 0x60), a)
            mstore(add(f, 0x80), e)
            mstore(add(f, 0xa0), P)
            success := staticcall(gas(), PRECOMPILE_MODEXP, f, 0xc0, f, 0x20)
            x := mload(f)
        }
        if (!success) {

            revert ProofInvalid();
        }
    }

    function invert_Fp(uint256 a) internal view returns (uint256 x) {
        x = exp(a, EXP_INVERSE_FP);
        if (mulmod(a, x, P) != 1) {

            revert ProofInvalid();
        }
    }

    function sqrt_Fp(uint256 a) internal view returns (uint256 x) {
        x = exp(a, EXP_SQRT_FP);
        if (mulmod(x, x, P) != a) {

            revert ProofInvalid();
        }
    }

    function isSquare_Fp(uint256 a) internal view returns (bool) {
        uint256 x = exp(a, EXP_SQRT_FP);
        return mulmod(x, x, P) == a;
    }

    function sqrt_Fp2(uint256 a0, uint256 a1, bool hint)
        internal
        view
        returns (uint256 x0, uint256 x1)
    {

        uint256 d = sqrt_Fp(addmod(mulmod(a0, a0, P), mulmod(a1, a1, P), P));
        if (hint) {
            d = negate(d);
        }

        x0 = sqrt_Fp(mulmod(addmod(a0, d, P), FRACTION_1_2_FP, P));
        x1 = mulmod(a1, invert_Fp(mulmod(x0, 2, P)), P);

        if (
            a0 != addmod(mulmod(x0, x0, P), negate(mulmod(x1, x1, P)), P)
                || a1 != mulmod(2, mulmod(x0, x1, P), P)
        ) {
            revert ProofInvalid();
        }
    }

    function compress_g1(uint256 x, uint256 y) internal view returns (uint256 c) {
        if (x >= P || y >= P) {

            revert ProofInvalid();
        }
        if (x == 0 && y == 0) {

            return 0;
        }

        uint256 y_pos = sqrt_Fp(addmod(mulmod(mulmod(x, x, P), x, P), 3, P));
        if (y == y_pos) {
            return (x << 1) | 0;
        } else if (y == negate(y_pos)) {
            return (x << 1) | 1;
        } else {

            revert ProofInvalid();
        }
    }

    function decompress_g1(uint256 c) internal view returns (uint256 x, uint256 y) {

        if (c == 0) {

            return (0, 0);
        }
        bool negate_point = c & 1 == 1;
        x = c >> 1;
        if (x >= P) {

            revert ProofInvalid();
        }

        y = sqrt_Fp(addmod(mulmod(mulmod(x, x, P), x, P), 3, P));
        if (negate_point) {
            y = negate(y);
        }
    }

    function compress_g2(uint256 x0, uint256 x1, uint256 y0, uint256 y1)
        internal
        view
        returns (uint256 c0, uint256 c1)
    {
        if (x0 >= P || x1 >= P || y0 >= P || y1 >= P) {

            revert ProofInvalid();
        }
        if ((x0 | x1 | y0 | y1) == 0) {

            return (0, 0);
        }

        uint256 y0_pos;
        uint256 y1_pos;
        {
            uint256 n3ab = mulmod(mulmod(x0, x1, P), P - 3, P);
            uint256 a_3 = mulmod(mulmod(x0, x0, P), x0, P);
            uint256 b_3 = mulmod(mulmod(x1, x1, P), x1, P);
            y0_pos = addmod(FRACTION_27_82_FP, addmod(a_3, mulmod(n3ab, x1, P), P), P);
            y1_pos = negate(addmod(FRACTION_3_82_FP, addmod(b_3, mulmod(n3ab, x0, P), P), P));
        }

        bool hint;
        {
            uint256 d = sqrt_Fp(addmod(mulmod(y0_pos, y0_pos, P), mulmod(y1_pos, y1_pos, P), P));
            hint = !isSquare_Fp(mulmod(addmod(y0_pos, d, P), FRACTION_1_2_FP, P));
        }

        (y0_pos, y1_pos) = sqrt_Fp2(y0_pos, y1_pos, hint);
        if (y0 == y0_pos && y1 == y1_pos) {
            c0 = (x0 << 2) | (hint ? 2 : 0) | 0;
            c1 = x1;
        } else if (y0 == negate(y0_pos) && y1 == negate(y1_pos)) {
            c0 = (x0 << 2) | (hint ? 2 : 0) | 1;
            c1 = x1;
        } else {

            revert ProofInvalid();
        }
    }

    function decompress_g2(uint256 c0, uint256 c1)
        internal
        view
        returns (uint256 x0, uint256 x1, uint256 y0, uint256 y1)
    {

        if (c0 == 0 && c1 == 0) {

            return (0, 0, 0, 0);
        }
        bool negate_point = c0 & 1 == 1;
        bool hint = c0 & 2 == 2;
        x0 = c0 >> 2;
        x1 = c1;
        if (x0 >= P || x1 >= P) {

            revert ProofInvalid();
        }

        uint256 n3ab = mulmod(mulmod(x0, x1, P), P - 3, P);
        uint256 a_3 = mulmod(mulmod(x0, x0, P), x0, P);
        uint256 b_3 = mulmod(mulmod(x1, x1, P), x1, P);

        y0 = addmod(FRACTION_27_82_FP, addmod(a_3, mulmod(n3ab, x1, P), P), P);
        y1 = negate(addmod(FRACTION_3_82_FP, addmod(b_3, mulmod(n3ab, x0, P), P), P));

        (y0, y1) = sqrt_Fp2(y0, y1, hint);
        if (negate_point) {
            y0 = negate(y0);
            y1 = negate(y1);
        }
    }

    function publicInputMSM(uint256[4] calldata input)
        internal
        view
        returns (uint256 x, uint256 y)
    {

        bool success = true;
        assembly ("memory-safe") {
            let f := mload(0x40)
            let g := add(f, 0x40)
            let s
            mstore(f, CONSTANT_X)
            mstore(add(f, 0x20), CONSTANT_Y)
            mstore(g, PUB_0_X)
            mstore(add(g, 0x20), PUB_0_Y)
            s := calldataload(input)
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_1_X)
            mstore(add(g, 0x20), PUB_1_Y)
            s :=  calldataload(add(input, 32))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_2_X)
            mstore(add(g, 0x20), PUB_2_Y)
            s :=  calldataload(add(input, 64))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_3_X)
            mstore(add(g, 0x20), PUB_3_Y)
            s :=  calldataload(add(input, 96))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            x := mload(f)
            y := mload(add(f, 0x20))
        }
        if (!success) {

            revert PublicInputNotInField();
        }
    }

    function compressProof(uint256[8] calldata proof)
        public
        view
        returns (uint256[4] memory compressed)
    {
        compressed[0] = compress_g1(proof[0], proof[1]);
        (compressed[2], compressed[1]) = compress_g2(proof[3], proof[2], proof[5], proof[4]);
        compressed[3] = compress_g1(proof[6], proof[7]);
    }

    function verifyCompressedProof(uint256[4] calldata compressedProof, uint256[4] calldata input)
        public
        view
    {
        (uint256 Ax, uint256 Ay) = decompress_g1(compressedProof[0]);
        (uint256 Bx0, uint256 Bx1, uint256 By0, uint256 By1) =
            decompress_g2(compressedProof[2], compressedProof[1]);
        (uint256 Cx, uint256 Cy) = decompress_g1(compressedProof[3]);
        (uint256 Lx, uint256 Ly) = publicInputMSM(input);

        uint256[24] memory pairings;

        pairings[0] = Ax;
        pairings[1] = Ay;
        pairings[2] = Bx1;
        pairings[3] = Bx0;
        pairings[4] = By1;
        pairings[5] = By0;

        pairings[6] = Cx;
        pairings[7] = Cy;
        pairings[8] = DELTA_NEG_X_1;
        pairings[9] = DELTA_NEG_X_0;
        pairings[10] = DELTA_NEG_Y_1;
        pairings[11] = DELTA_NEG_Y_0;

        pairings[12] = ALPHA_X;
        pairings[13] = ALPHA_Y;
        pairings[14] = BETA_NEG_X_1;
        pairings[15] = BETA_NEG_X_0;
        pairings[16] = BETA_NEG_Y_1;
        pairings[17] = BETA_NEG_Y_0;

        pairings[18] = Lx;
        pairings[19] = Ly;
        pairings[20] = GAMMA_NEG_X_1;
        pairings[21] = GAMMA_NEG_X_0;
        pairings[22] = GAMMA_NEG_Y_1;
        pairings[23] = GAMMA_NEG_Y_0;

        bool success;
        uint256[1] memory output;
        assembly ("memory-safe") {
            success := staticcall(gas(), PRECOMPILE_VERIFY, pairings, 0x300, output, 0x20)
        }
        if (!success || output[0] != 1) {

            revert ProofInvalid();
        }
    }

    function verifyProof(uint256[8] calldata proof, uint256[4] calldata input) public view {
        (uint256 x, uint256 y) = publicInputMSM(input);

        bool success;
        assembly ("memory-safe") {
            let f := mload(0x40)

            calldatacopy(f, proof, 0x100)

            mstore(add(f, 0x100), DELTA_NEG_X_1)
            mstore(add(f, 0x120), DELTA_NEG_X_0)
            mstore(add(f, 0x140), DELTA_NEG_Y_1)
            mstore(add(f, 0x160), DELTA_NEG_Y_0)
            mstore(add(f, 0x180), ALPHA_X)
            mstore(add(f, 0x1a0), ALPHA_Y)
            mstore(add(f, 0x1c0), BETA_NEG_X_1)
            mstore(add(f, 0x1e0), BETA_NEG_X_0)
            mstore(add(f, 0x200), BETA_NEG_Y_1)
            mstore(add(f, 0x220), BETA_NEG_Y_0)
            mstore(add(f, 0x240), x)
            mstore(add(f, 0x260), y)
            mstore(add(f, 0x280), GAMMA_NEG_X_1)
            mstore(add(f, 0x2a0), GAMMA_NEG_X_0)
            mstore(add(f, 0x2c0), GAMMA_NEG_Y_1)
            mstore(add(f, 0x2e0), GAMMA_NEG_Y_0)

            success := staticcall(gas(), PRECOMPILE_VERIFY, f, 0x300, f, 0x20)

            success := and(success, mload(f))
        }
        if (!success) {

            revert ProofInvalid();
        }
    }

       mapping(address => uint) public bids;
       address public highestBidder;
       uint public highestBid;

       function placeBid_UncheckedWriteInAuction_a023() external payable {
           require(msg.value > highestBid, "Bid not high enough");
           highestBidder = msg.sender;
           highestBid = msg.value;
           bids[msg.sender] = msg.value;
       }

}
