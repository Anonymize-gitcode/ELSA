pragma solidity ^0.8.0;
interface IVerifier {
    function verify(
        uint256[8] memory _proof,
        SnarkCommon.VerifyingKey memory vk,
        uint256[] memory inputs
    ) external view returns (bool);
}
contract SnarkConstants {
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant PAD_PUBKEY_X =
        10457101036533406547632367118273992217979173478358440826365724437999023779287;
    uint256 internal constant PAD_PUBKEY_Y =
        19824078218392094440610104313265183977899662750282163392862422243483260492317;
    uint256 internal constant NOTHING_UP_MY_SLEEVE =
        8370432830353022751713833565135785980866757267633941821328460903436894336785;
    mapping(address => uint) balances_UnspecifiedMappingVisibility_ll6a; // SWC-128 violation: Mapping visibility not explicitly specified
}
contract SnarkCommon {
    struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] ic;
    }
}
library Pairing {
    uint256 public constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    struct G1Point {
        uint256 x;
        uint256 y;
    }
    struct G2Point {
        uint256[2] x;
        uint256[2] y;
    }
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        if (p.x == 0 && p.y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
        }
    }
    function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        bool success;
        assembly {
            success := staticcall(gas(), 6, input, 0x80, r, 0x40)
            switch success
            case 0 {
                invalid()
            }
        }
        if (!success) {
            revert("Pairing addition failed");
        }
    }
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, r, 0x40)
            switch success
            case 0 {
                invalid()
            }
        }
        if (!success) {
            revert("Pairing multiplication failed");
        }
    }
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool isValid) {
        G1Point[4] memory p1;
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        G2Point[4] memory p2;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);
        for (uint8 i = 0; i < 4; ) {
            uint8 j = i * 6;
            input[j + 0] = p1[i].x;
            input[j + 1] = p1[i].y;
            input[j + 2] = p2[i].x[0];
            input[j + 3] = p2[i].x[1];
            input[j + 4] = p2[i].y[0];
            input[j + 5] = p2[i].y[1];
            unchecked {
                i++;
            }
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            switch success
            case 0 {
                invalid()
            }
        }
        if (!success) {
            revert("Pairing opcode failed");
        }
        isValid = out[0] != 0;
    }
}
contract Verifier is IVerifier, SnarkConstants, SnarkCommon {
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    using Pairing for *;
    uint256 public constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    function verify(
        uint256[8] memory _proof,
        VerifyingKey memory vk,
        uint256[] calldata inputs
    ) public view override returns (bool isValid) {
        Proof memory proof;
        proof.a = Pairing.G1Point(_proof[0], _proof[1]);
        proof.b = Pairing.G2Point([_proof[2], _proof[3]], [_proof[4], _proof[5]]);
        proof.c = Pairing.G1Point(_proof[6], _proof[7]);
        checkPoint(proof.a.x);
        checkPoint(proof.a.y);
        checkPoint(proof.b.x[0]);
        checkPoint(proof.b.y[0]);
        checkPoint(proof.b.x[1]);
        checkPoint(proof.b.y[1]);
        checkPoint(proof.c.x);
        checkPoint(proof.c.y);
        Pairing.G1Point memory vkX = Pairing.G1Point(0, 0);
        uint256 inputsLength = inputs.length;
        for (uint256 i = 0; i < inputsLength; ) {
            uint256 input = inputs[i];
            if (input >= SNARK_SCALAR_FIELD) {
                revert("Invalid input value");
            }
            vkX = Pairing.plus(vkX, Pairing.scalarMul(vk.ic[i + 1], input));
            unchecked {
                i++;
            }
        }
        vkX = Pairing.plus(vkX, vk.ic[0]);
        isValid = Pairing.pairing(
            Pairing.negate(proof.a),
            proof.b,
            vk.alpha1,
            vk.beta2,
            vkX,
            vk.gamma2,
            proof.c,
            vk.delta2
        );
    }
    function checkPoint(uint256 point) internal pure {
        if (point >= PRIME_Q) {
            revert("Invalid proof value");
        }
    }
}