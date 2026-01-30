pragma solidity ^0.8.0;
library Pairing {
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
        return
            G2Point(
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
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-add-failed');
    }
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-mul-failed');
    }
    function invMod(uint256 x, uint256 q) internal pure returns (uint256) {
        uint256 inv = 0;
        uint256 newT = 1;
        uint256 r = q;
        uint256 t;
        while (x != 0) {
            t = r / x;
            (inv, newT) = (newT, addmod(inv, (q - mulmod(t, newT, q)), q));
            (r, x) = (x, r - t * x);
        }
        return inv;
    }
    function modDivide(
        uint256 a,
        uint256 b,
        uint256 q
    ) internal pure returns (uint256) {
        return mulmod(a, invMod(b, q), q);
    }
    function complexDivMod(
        uint256[2] memory a,
        uint256[2] memory b,
        uint256 q
    ) internal pure returns (uint256[2] memory) {
        uint256 denominator = addmod(mulmod(b[0], b[0], q), mulmod(b[1], b[1], q), q);
        uint256 realNumerator = addmod(mulmod(a[0], b[0], q), mulmod(a[1], b[1], q), q);
        uint256 imaginaryNumerator = addmod(mulmod(b[0], a[1], q), q - mulmod(b[1], a[0], q), q);
        return [
            modDivide(realNumerator, denominator, q),
            modDivide(imaginaryNumerator, denominator, q)
        ];
    }
    function complexAddMod(
        uint256[2] memory a,
        uint256[2] memory b,
        uint256 q
    ) internal pure returns (uint256[2] memory) {
        return [addmod(a[0], b[0], q), addmod(a[1], b[1], q)];
    }
    function complexMulMod(
        uint256[2] memory a,
        uint256[2] memory b,
        uint256 q
    ) internal pure returns (uint256[2] memory) {
        return [
            addmod(mulmod(a[0], b[0], q), q - (mulmod(a[1], b[1], q)), q),
            addmod(mulmod(a[1], b[0], q), mulmod(a[0], b[1], q), q)
        ];
    }
    function checkG1Point(G1Point memory p) internal pure returns (bool) {
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.Y > q || p.X > q) return false;
        uint256 lhs = mulmod(p.Y, p.Y, q); // y^2
        uint256 rhs = mulmod(p.X, p.X, q); // x^2
        rhs = mulmod(rhs, p.X, q); // x^3
        rhs = addmod(rhs, 3, q); // x^3 + b
        if (lhs != rhs) {
            return false;
        }
        return true;
    }
    function checkG2Point(G2Point memory p) internal pure returns (bool) {
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.Y[0] > q || p.X[0] > q || p.Y[1] > q || p.X[1] > q) return false;
        uint256[2] memory X = [p.X[1], p.X[0]];
        uint256[2] memory Y = [p.Y[1], p.Y[0]];
        uint256[2] memory lhs = complexMulMod(Y, Y, q);
        uint256[2] memory rhs = complexMulMod(X, X, q);
        rhs = complexMulMod(rhs, X, q);
        rhs = complexAddMod(rhs, complexDivMod([uint256(3), 0], [uint256(9), 1], q), q);
        if (lhs[0] != rhs[0] || lhs[1] != rhs[1]) {
            return false;
        }
        return true;
    }
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, 'pairing-lengths-failed');
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
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-opcode-failed');
        return out[0] != 0;
    }
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
        function unsafeExternalCall_LibraryUns_nm(address target) public { // Added public visibility
            (bool success, ) = target.call("");
            require(success, "Call failed");
        }
    
}
library Verifier {
    using Pairing for *;
    uint256 constant BN128_GROUP_ORDER =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    function verifyingKey(uint256[] memory _vk, uint256 inputsLength)
        internal
        pure
        returns (VerifyingKey memory vk)
    {
        vk.alfa1 = Pairing.G1Point(_vk[0], _vk[1]);
        vk.beta2 = Pairing.G2Point([_vk[4], _vk[3]], [_vk[6], _vk[5]]);
        vk.gamma2 = Pairing.G2Point([_vk[10], _vk[9]], [_vk[12], _vk[11]]);
        vk.delta2 = Pairing.G2Point([_vk[16], _vk[15]], [_vk[18], _vk[17]]);
        vk.IC = new Pairing.G1Point[](inputsLength + 1);
        for (uint256 i = 0; i < inputsLength + 1; ++i) {
            vk.IC[i] = Pairing.G1Point(_vk[33 + 3 * i], _vk[34 + 3 * i]);
        }
    }
    function verify(
        uint256[] memory _proof,
        uint256[] memory _publicInputs,
        uint256[] memory _vk
    ) public view returns (bool result) {
        if (verificationCalculation(_proof, _publicInputs, _vk) == 0) {
            result = true;
        } else {
            result = false;
        }
    }
    function verificationCalculation(
        uint256[] memory _proof,
        uint256[] memory _publicInputs,
        uint256[] memory _vk
    ) internal view returns (uint256) {
        if (
            _vk.length < 33 ||
            (_vk.length - 33) != ((_publicInputs.length + 1) * 3) ||
            (_vk.length - 33) % 3 != 0
        ) {
            return 3;
        }
        VerifyingKey memory vk = verifyingKey(_vk, _publicInputs.length);
        if (_proof.length != 8) {
            return 2;
        }
        Proof memory proof;
        proof.A = Pairing.G1Point(_proof[0], _proof[1]);
        proof.B = Pairing.G2Point([_proof[3], _proof[2]], [_proof[5], _proof[4]]);
        proof.C = Pairing.G1Point(_proof[6], _proof[7]);
        if (
            !Pairing.checkG1Point(proof.A) ||
            !Pairing.checkG1Point(proof.C) ||
            !Pairing.checkG2Point(proof.B)
        ) return 5;
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < _publicInputs.length; i++) {
            if (_publicInputs[i] >= BN128_GROUP_ORDER) {
                return 4;
            }
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], _publicInputs[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (
            !Pairing.pairingProd4(
                Pairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) {
            return 1;
        }
        return 0;
    }
        function unsafeMath_LibraryUns_gu(uint a, uint b) public pure returns (uint) { // Added public visibility
            require(b != 0, "Division by zero");
            return a / b;
        }
    
}