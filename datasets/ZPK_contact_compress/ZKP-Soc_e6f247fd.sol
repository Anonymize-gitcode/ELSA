pragma solidity ^0.8.0;
library Pairing {
    string constant INVALID_PROOF = "Invalid proof provided.";
    
    uint256 constant BASE_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant SCALAR_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    function P2() internal pure returns (G2Point memory) {
        return G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
    }
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        if (p.X >= BASE_MODULUS || p.Y >= BASE_MODULUS) revert(INVALID_PROOF);
        return G1Point(p.X, BASE_MODULUS - p.Y);
    }
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input = [p1.X, p1.Y, p2.X, p2.Y];
        bool success;
        assembly {
            success := staticcall(gas(), 6, input, 0x80, r, 0x40)
        }
        if (!success) revert(INVALID_PROOF);
    }
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        if (s >= SCALAR_MODULUS) revert(INVALID_PROOF);
        uint256[3] memory input = [p.X, p.Y, s];
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, r, 0x40)
        }
        if (!success) revert(INVALID_PROOF);
    }
    function pairingCheck(G1Point[] memory p1, G2Point[] memory p2) internal view {
        if (p1.length != p2.length) revert(INVALID_PROOF);
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        if (!success || out[0] != 1) revert(INVALID_PROOF);
    }
}
contract Verifier17 {
    string constant INVALID_PROOF = "Invalid proof provided.";
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );
        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132, 6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679, 10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531, 8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [15629200772768268814959330350023920183087521275477047626405113853190187031523, 13589689305661231568162336263197960570915890299814486885851912452076929115480],
            [11464919285924930973853174493551975632739604254498590354200272115844983493029, 16004221700357242255845535848024178544616388017965468694776181247983831995562]
        );
        vk.IC = new Pairing.G1Point[](5);
        vk.IC[0] = Pairing.G1Point(
            17789438292552571310739605737896030466581277887660997531707911256058650850910,
            4112657509505371631825493224748310061184972897405589115208158208294581472016
        );
        vk.IC[1] = Pairing.G1Point(
            3322052920119834475842380240689494113984887785733316517680891208549118967155,
            381029395779795399840019487059126246243641886087320875571067736504031557148
        );
        vk.IC[2] = Pairing.G1Point(
            8777645223617381095463415690983421308854368583891690388850387317049320450400,
            11923582117369144413749726090967341613266070909169947059497952692052020331958
        );
        vk.IC[3] = Pairing.G1Point(
            15493263571528401950994933073246603557158047091963487223668240334879173885581,
            6315532173951617115856055775098532808695228294437279844344466163873167020700
        );
        vk.IC[4] = Pairing.G1Point(
            3481637421055377106140197938175958155334313900824697193932986771017625492245,
            20088416136090515091300914661950097694450984520235647990572441134215240947932
        );
    }
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[4] memory input
    ) public view {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        VerifyingKey memory vk = verifyingKey();
        if (input.length + 1 != vk.IC.length) revert(INVALID_PROOF);
        Pairing.G1Point memory vk_x = vk.IC[0];
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[1], input[0]));
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[2], input[1]));
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[3], input[2]));
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[4], input[3]));
        Pairing.G1Point[] memory p1 = new Pairing.G1Point[](4);
        Pairing.G2Point[] memory p2 = new Pairing.G2Point[](4);
        p1[0] = Pairing.negate(proof.A);
        p2[0] = proof.B;
        p1[1] = vk.alfa1;
        p2[1] = vk.beta2;
        p1[2] = vk_x;
        p2[2] = vk.gamma2;
        p1[3] = proof.C;
        p2[3] = vk.delta2;
        Pairing.pairingCheck(p1, p2);
    }
       fallback() external payable {
       }
       
       mapping(address => uint) public balances;
       function resetBalance_SensitiveFunctionPublic_r0fb(address _user) public {
           balances[_user] = 0;
       }
       
}