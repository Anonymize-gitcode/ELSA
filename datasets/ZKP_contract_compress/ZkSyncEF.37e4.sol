pragma solidity 0.8.28;

interface IVerifierV2 {

    function verify(uint256[] calldata _publicInputs, uint256[] calldata _proof) external view returns (bool);

    function verificationKeyHash() external view returns (bytes32);

}

contract L1VerifierFflonk is IVerifierV2 {

    uint32 internal constant DST_0 = 0;

    uint32 internal constant DST_1 = 1;

    uint32 internal constant DST_CHALLENGE = 2;

    uint256 internal constant FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 internal constant Q_MOD = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    uint256 internal constant R_MOD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 internal constant BN254_B_COEFF = 3;

    uint256 internal constant VK_NUM_INPUTS = 1;

    uint256 internal constant VK_C0_G1_X = 0x0e2ded5cfc9ea295ca630aed1ed641e12a89d83e60e59bd9b467ad5668b5357d;

    uint256 internal constant VK_C0_G1_Y = 0x2940e9a4985d775fba0bf93338a86999e56fc13bdde4078ad549dee2fad1dbf7;

    uint256 internal constant VK_NON_RESIDUES_0 = 0x05;

    uint256 internal constant VK_NON_RESIDUES_1 = 0x07;

    uint256 internal constant VK_G2_ELEMENT_0_X1 = 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;

    uint256 internal constant VK_G2_ELEMENT_0_X2 = 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;

    uint256 internal constant VK_G2_ELEMENT_0_Y1 = 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;

    uint256 internal constant VK_G2_ELEMENT_0_Y2 = 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    uint256 internal constant VK_G2_ELEMENT_1_X1 = 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1;

    uint256 internal constant VK_G2_ELEMENT_1_X2 = 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0;

    uint256 internal constant VK_G2_ELEMENT_1_Y1 = 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4;

    uint256 internal constant VK_G2_ELEMENT_1_Y2 = 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55;

    uint256 internal constant ONE = 1;

    uint256 internal constant DOMAIN_SIZE = 8388608;

    uint256 internal constant OMEGA = 0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863;

    uint256 internal constant TRANSCRIPT_BEGIN_SLOT = 0x200;

    uint256 internal constant TRANSCRIPT_DST_BYTE_SLOT = 0x203;

    uint256 internal constant TRANSCRIPT_STATE_0_SLOT = 0x204;

    uint256 internal constant TRANSCRIPT_STATE_1_SLOT = 0x224;

    uint256 internal constant TRANSCRIPT_CHALLENGE_SLOT = 0x244;

    uint256 internal constant PVS_BETA = 0x264 + 0x00;

    uint256 internal constant PVS_GAMMA = 0x264 + 0x20;

    uint256 internal constant PVS_R = 0x264 + 0x40;

    uint256 internal constant PVS_Z = 0x264 + 0x60;

    uint256 internal constant PVS_Z_OMEGA = 0x264 + 0x80;

    uint256 internal constant PVS_ALPHA_0 = 0x264 + 0xa0;

    uint256 internal constant PVS_ALPHA_1 = 0x264 + 0xc0;

    uint256 internal constant PVS_Y = 0x264 + 0xe0;

    uint256 internal constant PVS_VANISHING_AT_Z = 0x264 + 0x100;

    uint256 internal constant PVS_VANISHING_AT_Z_INV = 0x264 + 0x120;

    uint256 internal constant PVS_L_0_AT_Z = 0x264 + 0x140;

    uint256 internal constant MAIN_GATE_QUOTIENT_AT_Z = 0x264 + 0x160;

    uint256 internal constant COPY_PERM_FIRST_QUOTIENT_AT_Z = 0x264 + 0x180;

    uint256 internal constant COPY_PERM_SECOND_QUOTIENT_AT_Z = 0x264 + 0x1a0;

    uint256 internal constant OPS_OPENING_POINTS = 0x264 + 0x1c0 + 0x00;

    uint256 internal constant OPS_Y_POWS = 0x264 + 0x1c0 + 0x80;

    uint256 internal constant PS_VANISHING_AT_Y = 0x264 + 0x1c0 + 0x1a0;

    uint256 internal constant PS_INV_ZTS0_AT_Y = 0x264 + 0x1c0 + 0x1c0;

    uint256 internal constant PS_SET_DIFFERENCES_AT_Y = 0x264 + 0x1c0 + 0x1e0;

    uint256 internal constant PS_MINUS_Z = 0x264 + 0x1c0 + 0x240;

    uint256 internal constant PS_R_EVALS = 0x264 + 0x1c0 + 0x280;

    uint256 internal constant MEM_PROOF_PUBLIC_INPUT_SLOT = 0x264 + 0x1c0 + 0x2e0;

    uint256 internal constant MEM_PROOF_COMMITMENT_0_G1_X = 0x264 + 0x1c0 + 0x2e0 + 0x20;

    uint256 internal constant MEM_PROOF_COMMITMENT_0_G1_Y = 0x264 + 0x1c0 + 0x2e0 + 0x40;

    uint256 internal constant MEM_PROOF_COMMITMENT_1_G1_X = 0x264 + 0x1c0 + 0x2e0 + 0x60;

    uint256 internal constant MEM_PROOF_COMMITMENT_1_G1_Y = 0x264 + 0x1c0 + 0x2e0 + 0x80;

    uint256 internal constant MEM_PROOF_COMMITMENT_2_G1_X = 0x264 + 0x1c0 + 0x2e0 + 0xa0;

    uint256 internal constant MEM_PROOF_COMMITMENT_2_G1_Y = 0x264 + 0x1c0 + 0x2e0 + 0xc0;

    uint256 internal constant MEM_PROOF_COMMITMENT_3_G1_X = 0x264 + 0x1c0 + 0x2e0 + 0xe0;

    uint256 internal constant MEM_PROOF_COMMITMENT_3_G1_Y = 0x264 + 0x1c0 + 0x2e0 + 0x100;

    uint256 internal constant MEM_PROOF_EVALUATIONS = 0x264 + 0x1c0 + 0x2e0 + 0x120;

    uint256 internal constant MEM_PROOF_MONTGOMERY_LAGRANGE_BASIS_INVERSE = 0x264 + 0x1c0 + 0x2e0 + 0x120 + 0x1e0;

    uint256 internal constant MEM_LAGRANGE_BASIS_DENOMS = 0x264 + 0x1c0 + 0x2e0 + 0x120 + 0x200;

    uint256 internal constant MEM_LAGRANGE_BASIS_DENOM_PRODUCTS = 0x264 + 0x1c0 + 0x2e0 + 0x120 + 0x440;

    uint256 internal constant MEM_PROOF_LAGRANGE_BASIS_EVALS = 0x264 + 0x1c0 + 0x2e0 + 0x120 + 0x680;

    uint256 internal constant PROOF_PUBLIC_INPUTS_LENGTH = 1;

    uint256 internal constant PROOF_LENGTH = 24;

    uint256 internal constant PROOF_EVALUATIONS_LENGTH = 15;

    uint256 internal constant TOTAL_LAGRANGE_BASIS_INVERSES_LENGTH = 18;

    function verificationKeyHash() external pure returns (bytes32) {
        return
            keccak256(

                abi.encodePacked(
                    VK_NUM_INPUTS,
                    VK_C0_G1_X,
                    VK_C0_G1_Y,
                    VK_NON_RESIDUES_0,
                    VK_NON_RESIDUES_1,
                    _getG2Elements()
                )
            );
    }

    function _getG2Elements() internal pure returns (bytes memory) {
        return

            abi.encodePacked(
                VK_G2_ELEMENT_0_X1,
                VK_G2_ELEMENT_0_X2,
                VK_G2_ELEMENT_0_Y1,
                VK_G2_ELEMENT_0_Y2,
                VK_G2_ELEMENT_1_X1,
                VK_G2_ELEMENT_1_X2,
                VK_G2_ELEMENT_1_Y1,
                VK_G2_ELEMENT_1_Y2
            );
    }

       receive() external payable {

       }

}
