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

    function verify(
        uint256[] calldata,
        uint256[] calldata
    ) external view virtual returns (bool) {

        assembly {

            load_inputs()
            initialize_transcript()

            compute_main_gate_quotient()
            compute_copy_permutation_quotients()

            initialize_opening_state()

            let result := check_openings()
            mstore(0, result)
            return(0, 0x20)

            function load_inputs() {

                let publicInputOffset := calldataload(0x04)
                let publicInputLengthInWords := calldataload(add(publicInputOffset, 0x04))

                if iszero(eq(publicInputLengthInWords, PROOF_PUBLIC_INPUTS_LENGTH)) {
                    revertWithMessage(32, "public input length is incorrect")
                }
                mstore(MEM_PROOF_PUBLIC_INPUT_SLOT, mod(calldataload(add(publicInputOffset, 0x24)), R_MOD))

                let proofLengthOffset := calldataload(0x24)
                let proofLengthInWords := calldataload(add(proofLengthOffset, 0x04))

                if iszero(eq(proofLengthInWords, PROOF_LENGTH)) {
                    revertWithMessage(25, "proof length is incorrect")
                }
                let proofOffset := add(proofLengthOffset, 0x24)

                {
                    let x := mod(calldataload(proofOffset), Q_MOD)
                    let y := mod(calldataload(add(proofOffset, 0x20)), Q_MOD)
                    let xx := mulmod(x, x, Q_MOD)
                    if iszero(eq(mulmod(y, y, Q_MOD), addmod(mulmod(x, xx, Q_MOD), 3, Q_MOD))) {
                        revertWithMessage(28, "commitment 0 is not on curve")
                    }
                    mstore(MEM_PROOF_COMMITMENT_0_G1_Y, y)
                    mstore(MEM_PROOF_COMMITMENT_0_G1_X, x)
                }
                {
                    let x := mod(calldataload(add(proofOffset, 0x40)), Q_MOD)
                    let y := mod(calldataload(add(proofOffset, 0x60)), Q_MOD)
                    let xx := mulmod(x, x, Q_MOD)
                    if iszero(eq(mulmod(y, y, Q_MOD), addmod(mulmod(x, xx, Q_MOD), 3, Q_MOD))) {
                        revertWithMessage(28, "commitment 1 is not on curve")
                    }
                    mstore(MEM_PROOF_COMMITMENT_1_G1_Y, y)
                    mstore(MEM_PROOF_COMMITMENT_1_G1_X, x)
                }
                {
                    let x := mod(calldataload(add(proofOffset, 0x80)), Q_MOD)
                    let y := mod(calldataload(add(proofOffset, 0xa0)), Q_MOD)
                    let xx := mulmod(x, x, Q_MOD)
                    if iszero(eq(mulmod(y, y, Q_MOD), addmod(mulmod(x, xx, Q_MOD), 3, Q_MOD))) {
                        revertWithMessage(28, "commitment 2 is not on curve")
                    }
                    mstore(MEM_PROOF_COMMITMENT_2_G1_Y, y)
                    mstore(MEM_PROOF_COMMITMENT_2_G1_X, x)
                }
                {
                    let x := mod(calldataload(add(proofOffset, 0xc0)), Q_MOD)
                    let y := mod(calldataload(add(proofOffset, 0xe0)), Q_MOD)
                    let xx := mulmod(x, x, Q_MOD)
                    if iszero(eq(mulmod(y, y, Q_MOD), addmod(mulmod(x, xx, Q_MOD), 3, Q_MOD))) {
                        revertWithMessage(28, "commitment 3 is not on curve")
                    }
                    mstore(MEM_PROOF_COMMITMENT_3_G1_Y, y)
                    mstore(MEM_PROOF_COMMITMENT_3_G1_X, x)
                }
                proofOffset := add(proofOffset, 0x100)

                for {
                    let i := 0
                } lt(i, PROOF_EVALUATIONS_LENGTH) {
                    i := add(i, 1)
                } {
                    let eval := mod(calldataload(add(proofOffset, mul(i, 0x20))), R_MOD)
                    let slot := add(MEM_PROOF_EVALUATIONS, mul(i, 0x20))
                    mstore(slot, eval)
                }
                proofOffset := add(proofOffset, mul(PROOF_EVALUATIONS_LENGTH, 0x20))

                mstore(MEM_PROOF_MONTGOMERY_LAGRANGE_BASIS_INVERSE, mod(calldataload(proofOffset), R_MOD))
            }

            function initialize_transcript() {
                if iszero(lt(DOMAIN_SIZE, R_MOD)) {
                    revertWithMessage(26, "Domain size >= R_MOD [ITS]")
                }
                if iszero(lt(OMEGA, R_MOD)) {
                    revertWithMessage(20, "Omega >= R_MOD [ITS]")
                }
                for {
                    let i := 0
                } lt(i, VK_NUM_INPUTS) {
                    i := add(i, 1)
                } {
                    update_transcript(mload(add(MEM_PROOF_PUBLIC_INPUT_SLOT, mul(i, 0x20))))
                }

                update_transcript(VK_C0_G1_X)
                update_transcript(VK_C0_G1_Y)

                update_transcript(mload(MEM_PROOF_COMMITMENT_0_G1_X))
                update_transcript(mload(MEM_PROOF_COMMITMENT_0_G1_Y))

                mstore(PVS_BETA, get_challenge(0))
                mstore(PVS_GAMMA, get_challenge(1))

                update_transcript(mload(MEM_PROOF_COMMITMENT_1_G1_X))
                update_transcript(mload(MEM_PROOF_COMMITMENT_1_G1_Y))

                mstore(PVS_R, get_challenge(2))

                for {
                    let i := 0
                } lt(i, PROOF_EVALUATIONS_LENGTH) {
                    i := add(i, 1)
                } {
                    update_transcript(mload(add(MEM_PROOF_EVALUATIONS, mul(i, 0x20))))
                }

                mstore(PVS_ALPHA_0, get_challenge(3))
                mstore(PVS_ALPHA_1, mulmod(mload(PVS_ALPHA_0), mload(PVS_ALPHA_0), R_MOD))

                update_transcript(mload(MEM_PROOF_COMMITMENT_2_G1_X))
                update_transcript(mload(MEM_PROOF_COMMITMENT_2_G1_Y))

                mstore(PVS_Y, get_challenge(4))
                mstore(PVS_Z, modexp(mload(PVS_R), 24))

                mstore(PVS_Z_OMEGA, mulmod(mload(PVS_Z), OMEGA, R_MOD))

                mstore(PVS_VANISHING_AT_Z, addmod(modexp(mload(PVS_Z), DOMAIN_SIZE), sub(R_MOD, ONE), R_MOD))

                mstore(
                    PVS_L_0_AT_Z,
                    modexp(mulmod(addmod(mload(PVS_Z), sub(R_MOD, ONE), R_MOD), DOMAIN_SIZE, R_MOD), sub(R_MOD, 2))
                )
                mstore(PVS_L_0_AT_Z, mulmod(mload(PVS_L_0_AT_Z), mload(PVS_VANISHING_AT_Z), R_MOD))
                mstore(PVS_VANISHING_AT_Z_INV, modexp(mload(PVS_VANISHING_AT_Z), sub(R_MOD, 2)))
            }

            function compute_main_gate_quotient() {

                let rhs := mload(add(MEM_PROOF_EVALUATIONS, mul(4, 0x20)))
                rhs := addmod(rhs, mulmod(mload(PVS_L_0_AT_Z), mload(MEM_PROOF_PUBLIC_INPUT_SLOT), R_MOD), R_MOD)
                for {
                    let i := 0
                } lt(i, 3) {
                    i := add(i, 1)
                } {
                    rhs := addmod(
                        rhs,
                        mulmod(
                            mload(add(MEM_PROOF_EVALUATIONS, mul(i, 0x20))),
                            mload(add(MEM_PROOF_EVALUATIONS, mul(add(8, i), 0x20))),
                            R_MOD
                        ),
                        R_MOD
                    )
                }

                rhs := mulmod(
                    addmod(
                        rhs,
                        mulmod(
                            mulmod(
                                mload(add(MEM_PROOF_EVALUATIONS, mul(3, 0x20))),
                                mload(add(MEM_PROOF_EVALUATIONS, mul(8, 0x20))),
                                R_MOD
                            ),
                            mload(add(MEM_PROOF_EVALUATIONS, mul(9, 0x20))),
                            R_MOD
                        ),
                        R_MOD
                    ),
                    mload(PVS_VANISHING_AT_Z_INV),
                    R_MOD
                )
                mstore(MAIN_GATE_QUOTIENT_AT_Z, rhs)
            }

            function compute_copy_permutation_quotients() {
                let tmp
                let tmp2

                let rhs := addmod(
                    addmod(
                        mulmod(mulmod(mload(PVS_BETA), mload(PVS_Z), R_MOD), VK_NON_RESIDUES_1, R_MOD),
                        mload(PVS_GAMMA),
                        R_MOD
                    ),
                    mload(add(MEM_PROOF_EVALUATIONS, mul(add(8, 2), 0x20))),
                    R_MOD
                )

                tmp := addmod(
                    addmod(
                        mulmod(mulmod(mload(PVS_BETA), mload(PVS_Z), R_MOD), VK_NON_RESIDUES_0, R_MOD),
                        mload(PVS_GAMMA),
                        R_MOD
                    ),
                    mload(add(MEM_PROOF_EVALUATIONS, mul(add(8, 1), 0x20))),
                    R_MOD
                )

                rhs := mulmod(rhs, tmp, R_MOD)

                rhs := mulmod(
                    mulmod(
                        rhs,
                        addmod(
                            addmod(mulmod(mload(PVS_BETA), mload(PVS_Z), R_MOD), mload(PVS_GAMMA), R_MOD),
                            mload(add(MEM_PROOF_EVALUATIONS, mul(8, 0x20))),
                            R_MOD
                        ),
                        R_MOD
                    ),
                    mload(add(MEM_PROOF_EVALUATIONS, mul(11, 0x20))),
                    R_MOD
                )

                tmp2 := mulmod(
                    mulmod(
                        addmod(
                            addmod(
                                mulmod(mload(PVS_BETA), mload(add(MEM_PROOF_EVALUATIONS, mul(add(5, 2), 0x20))), R_MOD),
                                mload(PVS_GAMMA),
                                R_MOD
                            ),
                            mload(add(MEM_PROOF_EVALUATIONS, mul(add(8, 2), 0x20))),
                            R_MOD
                        ),
                        mload(add(MEM_PROOF_EVALUATIONS, mul(12, 0x20))),
                        R_MOD
                    ),
                    addmod(
                        addmod(
                            mulmod(mload(PVS_BETA), mload(add(MEM_PROOF_EVALUATIONS, mul(add(5, 1), 0x20))), R_MOD),
                            mload(PVS_GAMMA),
                            R_MOD
                        ),
                        mload(add(MEM_PROOF_EVALUATIONS, mul(add(8, 1), 0x20))),
                        R_MOD
                    ),
                    R_MOD
                )

                tmp := addmod(
                    addmod(
                        mulmod(mload(PVS_BETA), mload(add(MEM_PROOF_EVALUATIONS, mul(5, 0x20))), R_MOD),
                        mload(PVS_GAMMA),
                        R_MOD
                    ),
                    mload(add(MEM_PROOF_EVALUATIONS, mul(8, 0x20))),
                    R_MOD
                )

                tmp2 := mulmod(tmp2, tmp, R_MOD)

                tmp2 := sub(R_MOD, tmp2)

                rhs := mulmod(addmod(rhs, tmp2, R_MOD), mload(PVS_VANISHING_AT_Z_INV), R_MOD)
                mstore(COPY_PERM_FIRST_QUOTIENT_AT_Z, rhs)

                rhs := mulmod(
                    mulmod(
                        addmod(mload(add(MEM_PROOF_EVALUATIONS, mul(11, 0x20))), sub(R_MOD, 1), R_MOD),
                        mload(PVS_L_0_AT_Z),
                        R_MOD
                    ),
                    mload(PVS_VANISHING_AT_Z_INV),
                    R_MOD
                )
                mstore(COPY_PERM_SECOND_QUOTIENT_AT_Z, rhs)
            }

            function precompute_partial_lagrange_basis_evaluations(start, num_polys, y, omega, h, product)
                -> interim_product
            {
                if gt(add(start, num_polys), TOTAL_LAGRANGE_BASIS_INVERSES_LENGTH) {
                    revertWithMessage(31, "Precompute Eval. Error [PLBEI1]")
                }
                let tmp := h
                let loop_length := sub(num_polys, 2)

                for {
                    let i := 0
                } lt(i, loop_length) {
                    i := add(i, 1)
                } {
                    tmp := mulmod(tmp, h, R_MOD)
                }

                let constant_part := mulmod(num_polys, tmp, R_MOD)

                let y_pow := mload(add(OPS_Y_POWS, mul(num_polys, 0x20)))

                let num_at_y := mulmod(tmp, h, R_MOD)

                num_at_y := sub(R_MOD, num_at_y)

                num_at_y := addmod(num_at_y, y_pow, R_MOD)

                let current_omega := 1
                for {
                    let i := 0
                } lt(i, num_polys) {
                    i := add(i, 1)
                } {

                    tmp := mulmod(current_omega, h, R_MOD)

                    tmp := sub(R_MOD, tmp)

                    tmp := addmod(tmp, y, R_MOD)

                    tmp := mulmod(tmp, constant_part, R_MOD)

                    mstore(add(MEM_LAGRANGE_BASIS_DENOMS, mul(add(start, i), 0x20)), tmp)

                    product := mulmod(product, tmp, R_MOD)

                    mstore(add(MEM_LAGRANGE_BASIS_DENOM_PRODUCTS, mul(add(start, i), 0x20)), product)

                    mstore(
                        add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(start, i), 0x20)),
                        mulmod(num_at_y, current_omega, R_MOD)
                    )

                    current_omega := mulmod(current_omega, omega, R_MOD)
                }

                interim_product := product
            }

            function temp_name_inner_function(num_polys, h, h_shifted) -> constant_parts_0, constant_parts_1, t_0, t_1 {
                let h_pows_0 := h
                let h_pows_1 := h_shifted
                let loop_length := sub(num_polys, 2)

                for {
                    let i := 0
                } lt(i, loop_length) {
                    i := add(i, 1)
                } {
                    h_pows_0 := mulmod(h_pows_0, h, R_MOD)
                    h_pows_1 := mulmod(h_pows_1, h_shifted, R_MOD)
                }
                constant_parts_0 := h_pows_0
                constant_parts_1 := h_pows_1

                h_pows_0 := mulmod(h_pows_0, h, R_MOD)

                h_pows_1 := mulmod(h_pows_1, h_shifted, R_MOD)

                constant_parts_0 := mulmod(constant_parts_0, h_pows_1, R_MOD)

                constant_parts_0 := sub(R_MOD, constant_parts_0)

                constant_parts_1 := mulmod(constant_parts_1, h_pows_0, R_MOD)

                constant_parts_1 := sub(R_MOD, constant_parts_1)

                let t_2 := mload(add(OPS_Y_POWS, mul(num_polys, 0x20)))

                t_1 := mulmod(h_pows_0, h_pows_1, R_MOD)

                t_0 := addmod(h_pows_0, h_pows_1, R_MOD)

                t_0 := mulmod(t_0, t_2, R_MOD)

                t_0 := sub(R_MOD, t_0)

                t_1 := addmod(t_1, t_0, R_MOD)

                t_2 := mulmod(t_2, t_2, R_MOD)

                t_1 := addmod(t_1, t_2, R_MOD)
                loop_length := sub(num_polys, 1)

                for {
                    let i := 0
                } lt(i, loop_length) {
                    i := add(i, 1)
                } {
                    h_pows_0 := mulmod(h_pows_0, h, R_MOD)
                    h_pows_1 := mulmod(h_pows_1, h_shifted, R_MOD)
                }

                constant_parts_0 := addmod(constant_parts_0, h_pows_0, R_MOD)

                constant_parts_0 := mulmod(constant_parts_0, num_polys, R_MOD)

                constant_parts_1 := addmod(constant_parts_1, h_pows_1, R_MOD)

                constant_parts_1 := mulmod(constant_parts_1, num_polys, R_MOD)
            }

            function precompute_partial_lagrange_basis_evaluations_for_union_set(
                start,
                num_polys,
                y,
                omega,
                h,
                h_shifted,
                interim_product
            ) -> final_product {
                if gt(add(start, mul(2, num_polys)), TOTAL_LAGRANGE_BASIS_INVERSES_LENGTH) {
                    revertWithMessage(32, "Precompute Eval. Error [PLBEIU1]")
                }

                let constant_parts_0, constant_parts_1, t_0, t_1 := temp_name_inner_function(num_polys, h, h_shifted)

                let current_omega := 1
                for {
                    let i := 0
                } lt(i, num_polys) {
                    i := add(i, 1)
                } {
                    t_0 := mulmod(current_omega, h, R_MOD)
                    t_0 := sub(R_MOD, t_0)
                    t_0 := addmod(t_0, y, R_MOD)

                    t_0 := mulmod(t_0, constant_parts_0, R_MOD)

                    mstore(add(MEM_LAGRANGE_BASIS_DENOMS, mul(add(start, i), 0x20)), t_0)

                    interim_product := mulmod(interim_product, t_0, R_MOD)

                    mstore(add(MEM_LAGRANGE_BASIS_DENOM_PRODUCTS, mul(add(start, i), 0x20)), interim_product)

                    mstore(
                        add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(start, i), 0x20)),
                        mulmod(t_1, current_omega, R_MOD)
                    )

                    current_omega := mulmod(current_omega, omega, R_MOD)
                }

                current_omega := 1
                for {
                    let i := 0
                } lt(i, num_polys) {
                    i := add(i, 1)
                } {
                    t_0 := mulmod(current_omega, h_shifted, R_MOD)
                    t_0 := sub(R_MOD, t_0)
                    t_0 := addmod(t_0, y, R_MOD)

                    t_0 := mulmod(t_0, constant_parts_1, R_MOD)

                    mstore(add(MEM_LAGRANGE_BASIS_DENOMS, mul(add(add(start, num_polys), i), 0x20)), t_0)

                    interim_product := mulmod(interim_product, t_0, R_MOD)

                    mstore(
                        add(MEM_LAGRANGE_BASIS_DENOM_PRODUCTS, mul(add(add(start, num_polys), i), 0x20)),
                        interim_product
                    )

                    mstore(
                        add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(add(start, num_polys), i), 0x20)),
                        mulmod(t_1, current_omega, R_MOD)
                    )

                    current_omega := mulmod(current_omega, omega, R_MOD)
                }

                final_product := interim_product
            }

            function precompute_all_lagrange_basis_evaluations_from_inverses() {
                let y := mload(PVS_Y)

                let product_0_7 := precompute_partial_lagrange_basis_evaluations(
                    0,
                    8,
                    y,
                    0x2b337de1c8c14f22ec9b9e2f96afef3652627366f8170a0a948dad4ac1bd5e80,
                    mload(add(OPS_OPENING_POINTS, mul(0, 0x20))),
                    1
                )
                let product_0_11 := precompute_partial_lagrange_basis_evaluations(
                    8,
                    4,
                    y,
                    0x30644e72e131a029048b6e193fd841045cea24f6fd736bec231204708f703636,
                    mload(add(OPS_OPENING_POINTS, mul(1, 0x20))),
                    product_0_7
                )
                let product_0_17 := precompute_partial_lagrange_basis_evaluations_for_union_set(
                    add(8, 4),
                    3,
                    y,
                    0x0000000000000000b3c4d79d41a917585bfc41088d8daaa78b17ea66b99c90dd,
                    mload(add(OPS_OPENING_POINTS, mul(2, 0x20))),
                    mload(add(OPS_OPENING_POINTS, mul(3, 0x20))),
                    product_0_11
                )

                let montgomery_inverse := mload(MEM_PROOF_MONTGOMERY_LAGRANGE_BASIS_INVERSE)

                if iszero(eq(mulmod(product_0_17, montgomery_inverse, R_MOD), 1)) {
                    revertWithMessage(30, "Precompute Eval. Error [PALBE]")
                }
                let temp := montgomery_inverse
                let loop_length := sub(TOTAL_LAGRANGE_BASIS_INVERSES_LENGTH, 1)
                for {
                    let i := loop_length
                } gt(i, 0) {
                    i := sub(i, 1)
                } {
                    mstore(
                        add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(i, 0x20)),
                        mulmod(
                            mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(i, 0x20))),
                            mulmod(mload(add(MEM_LAGRANGE_BASIS_DENOM_PRODUCTS, mul(sub(i, 1), 0x20))), temp, R_MOD),
                            R_MOD
                        )
                    )
                    temp := mulmod(temp, mload(add(MEM_LAGRANGE_BASIS_DENOMS, mul(i, 0x20))), R_MOD)
                }
                mstore(
                    add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(0, 0x20)),
                    mulmod(mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(0, 0x20))), temp, R_MOD)
                )
            }

            function compute_opening_points() {

                let pvs_r := mload(PVS_R)
                let r_2 := mulmod(pvs_r, pvs_r, R_MOD)
                let r_3 := mulmod(r_2, pvs_r, R_MOD)
                let r_6 := mulmod(r_3, r_3, R_MOD)
                let r_8 := mulmod(r_6, r_2, R_MOD)

                mstore(add(OPS_OPENING_POINTS, mul(0, 0x20)), r_3)

                mstore(add(OPS_OPENING_POINTS, mul(1, 0x20)), r_6)

                mstore(add(OPS_OPENING_POINTS, mul(2, 0x20)), r_8)

                mstore(
                    add(OPS_OPENING_POINTS, mul(3, 0x20)),
                    mulmod(r_8, 0x0925f0bd364638ec3084b45fc27895f8f3f6f079096600fe946c8e9db9a47124, R_MOD)
                )
            }

            function initialize_opening_state() {
                compute_opening_points()
                let acc := 1
                for {
                    let i := 0
                } lt(i, 9) {
                    i := add(i, 1)
                } {
                    mstore(add(OPS_Y_POWS, mul(i, 0x20)), acc)
                    acc := mulmod(acc, mload(PVS_Y), R_MOD)
                }
                precompute_all_lagrange_basis_evaluations_from_inverses()
            }

            function evaluate_r_polys_at_point_unrolled(
                main_gate_quotient_at_z,
                copy_perm_first_quotient_at_z,
                copy_perm_second_quotient_at_z
            ) {
                let omega_h
                let c

                omega_h := mload(add(OPS_OPENING_POINTS, mul(0, 0x20)))
                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(7, 0x20))), omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 7) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(7, i), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(MEM_PROOF_EVALUATIONS), R_MOD)
                mstore(
                    PS_R_EVALS,
                    addmod(
                        mload(PS_R_EVALS),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(0, 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x2b337de1c8c14f22ec9b9e2f96afef3652627366f8170a0a948dad4ac1bd5e80,
                    mload(add(OPS_OPENING_POINTS, mul(0, 0x20))),
                    R_MOD
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(7, 0x20))), omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 7) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(7, i), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(MEM_PROOF_EVALUATIONS), R_MOD)
                mstore(
                    PS_R_EVALS,
                    addmod(
                        mload(PS_R_EVALS),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(1, 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x30644e72e131a029048b6e193fd841045cea24f6fd736bec231204708f703636,
                    mload(add(OPS_OPENING_POINTS, mul(0, 0x20))),
                    R_MOD
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(7, 0x20))), omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 7) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(7, i), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(MEM_PROOF_EVALUATIONS), R_MOD)
                mstore(
                    PS_R_EVALS,
                    addmod(
                        mload(PS_R_EVALS),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(2, 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x1d59376149b959ccbd157ac850893a6f07c2d99b3852513ab8d01be8e846a566,
                    mload(add(OPS_OPENING_POINTS, mul(0, 0x20))),
                    R_MOD
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(7, 0x20))), omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 7) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(7, i), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(MEM_PROOF_EVALUATIONS), R_MOD)
                mstore(
                    PS_R_EVALS,
                    addmod(
                        mload(PS_R_EVALS),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(3, 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000,
                    mload(add(OPS_OPENING_POINTS, mul(0, 0x20))),
                    R_MOD
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(7, 0x20))), omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 7) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(7, i), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(MEM_PROOF_EVALUATIONS), R_MOD)
                mstore(
                    PS_R_EVALS,
                    addmod(
                        mload(PS_R_EVALS),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(4, 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x0530d09118705106cbb4a786ead16926d5d174e181a26686af5448492e42a181,
                    mload(add(OPS_OPENING_POINTS, mul(0, 0x20))),
                    R_MOD
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(7, 0x20))), omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 7) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(7, i), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(MEM_PROOF_EVALUATIONS), R_MOD)
                mstore(
                    PS_R_EVALS,
                    addmod(
                        mload(PS_R_EVALS),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(5, 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x0000000000000000b3c4d79d41a91758cb49c3517c4604a520cff123608fc9cb,
                    mload(add(OPS_OPENING_POINTS, mul(0, 0x20))),
                    R_MOD
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(7, 0x20))), omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 7) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(7, i), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(MEM_PROOF_EVALUATIONS), R_MOD)
                mstore(
                    PS_R_EVALS,
                    addmod(
                        mload(PS_R_EVALS),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(6, 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x130b17119778465cfb3acaee30f81dee20710ead41671f568b11d9ab07b95a9b,
                    mload(add(OPS_OPENING_POINTS, mul(0, 0x20))),
                    R_MOD
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(7, 0x20))), omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 7) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(7, i), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(MEM_PROOF_EVALUATIONS), R_MOD)
                mstore(
                    PS_R_EVALS,
                    addmod(
                        mload(PS_R_EVALS),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(7, 0x20))), R_MOD),
                        R_MOD
                    )
                )

                omega_h := mload(add(OPS_OPENING_POINTS, mul(1, 0x20)))

                c := mulmod(main_gate_quotient_at_z, omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 3) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(sub(add(8, 4), i), 1), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(sub(add(8, 4), 3), 1), 0x20))), R_MOD)

                mstore(
                    add(PS_R_EVALS, mul(1, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(1, 0x20))),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(8, 0), 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x30644e72e131a029048b6e193fd841045cea24f6fd736bec231204708f703636,
                    mload(add(OPS_OPENING_POINTS, mul(1, 0x20))),
                    R_MOD
                )

                c := mulmod(main_gate_quotient_at_z, omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 3) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(sub(add(8, 4), i), 1), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(sub(add(8, 4), 3), 1), 0x20))), R_MOD)
                mstore(
                    add(PS_R_EVALS, mul(1, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(1, 0x20))),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(8, 1), 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000,
                    mload(add(OPS_OPENING_POINTS, mul(1, 0x20))),
                    R_MOD
                )

                c := mulmod(main_gate_quotient_at_z, omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 3) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(sub(add(8, 4), i), 1), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(sub(add(8, 4), 3), 1), 0x20))), R_MOD)
                mstore(
                    add(PS_R_EVALS, mul(1, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(1, 0x20))),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(8, 2), 0x20))), R_MOD),
                        R_MOD
                    )
                )
                omega_h := mulmod(
                    0x0000000000000000b3c4d79d41a91758cb49c3517c4604a520cff123608fc9cb,
                    mload(add(OPS_OPENING_POINTS, mul(1, 0x20))),
                    R_MOD
                )

                c := mulmod(main_gate_quotient_at_z, omega_h, R_MOD)
                for {
                    let i := 1
                } lt(i, 3) {
                    i := add(i, 1)
                } {
                    c := mulmod(
                        addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(sub(add(8, 4), i), 1), 0x20))), R_MOD),
                        omega_h,
                        R_MOD
                    )
                }
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(sub(sub(add(8, 4), 3), 1), 0x20))), R_MOD)
                mstore(
                    add(PS_R_EVALS, mul(1, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(1, 0x20))),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(8, 3), 0x20))), R_MOD),
                        R_MOD
                    )
                )

                omega_h := mload(add(OPS_OPENING_POINTS, mul(2, 0x20)))
                let omega_h_shifted := mload(add(OPS_OPENING_POINTS, mul(3, 0x20)))
                c := mulmod(copy_perm_second_quotient_at_z, omega_h, R_MOD)
                c := mulmod(addmod(c, copy_perm_first_quotient_at_z, R_MOD), omega_h, R_MOD)
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(11, 0x20))), R_MOD)
                mstore(
                    add(PS_R_EVALS, mul(2, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(2, 0x20))),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(add(8, 4), 0), 0x20))), R_MOD),
                        R_MOD
                    )
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(add(12, 2), 0x20))), omega_h_shifted, R_MOD)
                c := mulmod(
                    addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(add(12, 1), 0x20))), R_MOD),
                    omega_h_shifted,
                    R_MOD
                )
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(12, 0x20))), R_MOD)
                mstore(
                    add(PS_R_EVALS, mul(2, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(2, 0x20))),
                        mulmod(
                            c,
                            mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(add(add(8, 4), 3), 0), 0x20))),
                            R_MOD
                        ),
                        R_MOD
                    )
                )

                omega_h := mulmod(
                    0x0000000000000000b3c4d79d41a917585bfc41088d8daaa78b17ea66b99c90dd,
                    mload(add(OPS_OPENING_POINTS, mul(2, 0x20))),
                    R_MOD
                )
                omega_h_shifted := mulmod(
                    0x0000000000000000b3c4d79d41a917585bfc41088d8daaa78b17ea66b99c90dd,
                    mload(add(OPS_OPENING_POINTS, mul(3, 0x20))),
                    R_MOD
                )

                c := mulmod(copy_perm_second_quotient_at_z, omega_h, R_MOD)
                c := mulmod(addmod(c, copy_perm_first_quotient_at_z, R_MOD), omega_h, R_MOD)
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(11, 0x20))), R_MOD)
                mstore(
                    add(PS_R_EVALS, mul(2, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(2, 0x20))),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(add(8, 4), 1), 0x20))), R_MOD),
                        R_MOD
                    )
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(add(12, 2), 0x20))), omega_h_shifted, R_MOD)
                c := mulmod(
                    addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(add(12, 1), 0x20))), R_MOD),
                    omega_h_shifted,
                    R_MOD
                )
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(12, 0x20))), R_MOD)
                mstore(
                    add(PS_R_EVALS, mul(2, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(2, 0x20))),
                        mulmod(
                            c,
                            mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(add(add(8, 4), 3), 1), 0x20))),
                            R_MOD
                        ),
                        R_MOD
                    )
                )

                omega_h := mulmod(
                    0x30644e72e131a029048b6e193fd84104cc37a73fec2bc5e9b8ca0b2d36636f23,
                    mload(add(OPS_OPENING_POINTS, mul(2, 0x20))),
                    R_MOD
                )
                omega_h_shifted := mulmod(
                    0x30644e72e131a029048b6e193fd84104cc37a73fec2bc5e9b8ca0b2d36636f23,
                    mload(add(OPS_OPENING_POINTS, mul(3, 0x20))),
                    R_MOD
                )

                c := mulmod(copy_perm_second_quotient_at_z, omega_h, R_MOD)
                c := mulmod(addmod(c, copy_perm_first_quotient_at_z, R_MOD), omega_h, R_MOD)
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(11, 0x20))), R_MOD)
                mstore(
                    add(PS_R_EVALS, mul(2, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(2, 0x20))),
                        mulmod(c, mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(add(8, 4), 2), 0x20))), R_MOD),
                        R_MOD
                    )
                )

                c := mulmod(mload(add(MEM_PROOF_EVALUATIONS, mul(add(12, 2), 0x20))), omega_h_shifted, R_MOD)
                c := mulmod(
                    addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(add(12, 1), 0x20))), R_MOD),
                    omega_h_shifted,
                    R_MOD
                )
                c := addmod(c, mload(add(MEM_PROOF_EVALUATIONS, mul(12, 0x20))), R_MOD)

                mstore(
                    add(PS_R_EVALS, mul(2, 0x20)),
                    addmod(
                        mload(add(PS_R_EVALS, mul(2, 0x20))),
                        mulmod(
                            c,
                            mload(add(MEM_PROOF_LAGRANGE_BASIS_EVALS, mul(add(add(add(8, 4), 3), 2), 0x20))),
                            R_MOD
                        ),
                        R_MOD
                    )
                )
            }

            function check_openings() -> out {

                let tmp
                evaluate_r_polys_at_point_unrolled(
                    mload(MAIN_GATE_QUOTIENT_AT_Z),
                    mload(COPY_PERM_FIRST_QUOTIENT_AT_Z),
                    mload(COPY_PERM_SECOND_QUOTIENT_AT_Z)
                )

                mstore(add(PS_MINUS_Z, mul(0, 0x20)), sub(R_MOD, mload(PVS_Z)))

                mstore(add(PS_MINUS_Z, mul(1, 0x20)), sub(R_MOD, mload(PVS_Z_OMEGA)))

                mstore(
                    add(PS_SET_DIFFERENCES_AT_Y, mul(0, 0x20)),
                    addmod(mload(add(OPS_Y_POWS, mul(3, 0x20))), mload(add(PS_MINUS_Z, mul(1, 0x20))), R_MOD)
                )
                tmp := addmod(mload(add(OPS_Y_POWS, mul(3, 0x20))), mload(add(PS_MINUS_Z, mul(0, 0x20))), R_MOD)
                mstore(
                    add(PS_SET_DIFFERENCES_AT_Y, mul(0, 0x20)),
                    mulmod(mload(add(PS_SET_DIFFERENCES_AT_Y, mul(0, 0x20))), tmp, R_MOD)
                )
                tmp := addmod(mload(add(OPS_Y_POWS, mul(4, 0x20))), mload(add(PS_MINUS_Z, mul(0, 0x20))), R_MOD)
                mstore(
                    add(PS_SET_DIFFERENCES_AT_Y, mul(0, 0x20)),
                    mulmod(mload(add(PS_SET_DIFFERENCES_AT_Y, mul(0, 0x20))), tmp, R_MOD)
                )
                mstore(PS_VANISHING_AT_Y, mload(add(PS_SET_DIFFERENCES_AT_Y, mul(0, 0x20))))
                mstore(PS_INV_ZTS0_AT_Y, modexp(mload(add(PS_SET_DIFFERENCES_AT_Y, mul(0, 0x20))), sub(R_MOD, 2)))

                mstore(
                    add(PS_SET_DIFFERENCES_AT_Y, mul(1, 0x20)),
                    addmod(mload(add(OPS_Y_POWS, mul(3, 0x20))), mload(add(PS_MINUS_Z, mul(1, 0x20))), R_MOD)
                )
                tmp := addmod(mload(add(OPS_Y_POWS, mul(3, 0x20))), mload(add(PS_MINUS_Z, mul(0, 0x20))), R_MOD)
                mstore(
                    add(PS_SET_DIFFERENCES_AT_Y, mul(1, 0x20)),
                    mulmod(mload(add(PS_SET_DIFFERENCES_AT_Y, mul(1, 0x20))), tmp, R_MOD)
                )
                tmp := addmod(mload(add(OPS_Y_POWS, mul(8, 0x20))), mload(add(PS_MINUS_Z, mul(0, 0x20))), R_MOD)
                mstore(
                    add(PS_SET_DIFFERENCES_AT_Y, mul(1, 0x20)),
                    mulmod(mload(add(PS_SET_DIFFERENCES_AT_Y, mul(1, 0x20))), tmp, R_MOD)
                )
                mstore(PS_VANISHING_AT_Y, mulmod(mload(PS_VANISHING_AT_Y), tmp, R_MOD))

                mstore(
                    add(PS_SET_DIFFERENCES_AT_Y, mul(2, 0x20)),
                    addmod(mload(add(OPS_Y_POWS, mul(4, 0x20))), mload(add(PS_MINUS_Z, mul(0, 0x20))), R_MOD)
                )
                tmp := addmod(mload(add(OPS_Y_POWS, mul(8, 0x20))), mload(add(PS_MINUS_Z, mul(0, 0x20))), R_MOD)
                mstore(
                    add(PS_SET_DIFFERENCES_AT_Y, mul(2, 0x20)),
                    mulmod(mload(add(PS_SET_DIFFERENCES_AT_Y, mul(2, 0x20))), tmp, R_MOD)
                )

                let ps_aggregated_commitment_g1_x := VK_C0_G1_X
                let ps_aggregated_commitment_g1_y := VK_C0_G1_Y

                let aggregated_r_at_y := mulmod(
                    mload(add(PS_SET_DIFFERENCES_AT_Y, mul(2, 0x20))),
                    mload(PS_INV_ZTS0_AT_Y),
                    R_MOD
                )
                aggregated_r_at_y := mulmod(aggregated_r_at_y, mload(PVS_ALPHA_1), R_MOD)

                let tp_g1_x, tp_g1_y := point_mul(
                    mload(MEM_PROOF_COMMITMENT_1_G1_X),
                    mload(MEM_PROOF_COMMITMENT_1_G1_Y),
                    aggregated_r_at_y
                )

                ps_aggregated_commitment_g1_x, ps_aggregated_commitment_g1_y := point_add(
                    ps_aggregated_commitment_g1_x,
                    ps_aggregated_commitment_g1_y,
                    tp_g1_x,
                    tp_g1_y
                )

                aggregated_r_at_y := mulmod(aggregated_r_at_y, mload(add(PS_R_EVALS, mul(2, 0x20))), R_MOD)

                tmp := mulmod(mload(add(PS_SET_DIFFERENCES_AT_Y, mul(1, 0x20))), mload(PS_INV_ZTS0_AT_Y), R_MOD)
                tmp := mulmod(tmp, mload(PVS_ALPHA_0), R_MOD)

                tp_g1_x, tp_g1_y := point_mul(
                    mload(MEM_PROOF_COMMITMENT_0_G1_X),
                    mload(MEM_PROOF_COMMITMENT_0_G1_Y),
                    tmp
                )

                ps_aggregated_commitment_g1_x, ps_aggregated_commitment_g1_y := point_add(
                    ps_aggregated_commitment_g1_x,
                    ps_aggregated_commitment_g1_y,
                    tp_g1_x,
                    tp_g1_y
                )

                tmp := mulmod(tmp, mload(add(PS_R_EVALS, mul(1, 0x20))), R_MOD)

                aggregated_r_at_y := addmod(aggregated_r_at_y, tmp, R_MOD)

                aggregated_r_at_y := addmod(aggregated_r_at_y, mload(PS_R_EVALS), R_MOD)
                tp_g1_x, tp_g1_y := point_mul(1, 2, aggregated_r_at_y)
                ps_aggregated_commitment_g1_x, ps_aggregated_commitment_g1_y := point_sub(
                    ps_aggregated_commitment_g1_x,
                    ps_aggregated_commitment_g1_y,
                    tp_g1_x,
                    tp_g1_y
                )

                mstore(PS_VANISHING_AT_Y, mulmod(mload(PS_VANISHING_AT_Y), mload(PS_INV_ZTS0_AT_Y), R_MOD))
                tp_g1_x, tp_g1_y := point_mul(
                    mload(MEM_PROOF_COMMITMENT_2_G1_X),
                    mload(MEM_PROOF_COMMITMENT_2_G1_Y),
                    mload(PS_VANISHING_AT_Y)
                )
                ps_aggregated_commitment_g1_x, ps_aggregated_commitment_g1_y := point_sub(
                    ps_aggregated_commitment_g1_x,
                    ps_aggregated_commitment_g1_y,
                    tp_g1_x,
                    tp_g1_y
                )

                tp_g1_x, tp_g1_y := point_mul(
                    mload(MEM_PROOF_COMMITMENT_3_G1_X),
                    mload(MEM_PROOF_COMMITMENT_3_G1_Y),
                    mload(PVS_Y)
                )
                ps_aggregated_commitment_g1_x, ps_aggregated_commitment_g1_y := point_add(
                    ps_aggregated_commitment_g1_x,
                    ps_aggregated_commitment_g1_y,
                    tp_g1_x,
                    tp_g1_y
                )
                let is_zero_commitment
                if iszero(mload(MEM_PROOF_COMMITMENT_3_G1_Y)) {
                    if gt(mload(MEM_PROOF_COMMITMENT_3_G1_X), 0) {
                        revertWithMessage(21, "non zero x value [CO]")
                    }
                    is_zero_commitment := 1
                }

                out := pairing_check(ps_aggregated_commitment_g1_x, ps_aggregated_commitment_g1_y, is_zero_commitment)
            }

            function update_transcript(value) {
                mstore8(TRANSCRIPT_DST_BYTE_SLOT, 0x00)
                mstore(TRANSCRIPT_CHALLENGE_SLOT, value)
                let newState0 := keccak256(TRANSCRIPT_BEGIN_SLOT, 0x64)
                mstore8(TRANSCRIPT_DST_BYTE_SLOT, 0x01)
                let newState1 := keccak256(TRANSCRIPT_BEGIN_SLOT, 0x64)
                mstore(TRANSCRIPT_STATE_1_SLOT, newState1)
                mstore(TRANSCRIPT_STATE_0_SLOT, newState0)
            }

            function get_challenge(challenge_counter) -> challenge {
                mstore8(TRANSCRIPT_DST_BYTE_SLOT, 0x02)
                mstore(TRANSCRIPT_CHALLENGE_SLOT, shl(224, challenge_counter))
                challenge := and(keccak256(TRANSCRIPT_BEGIN_SLOT, 0x48), FR_MASK)
            }

            function point_mul(p_x, p_y, s) -> t_x, t_y {
                mstore(0x80, p_x)
                mstore(0xa0, p_y)
                mstore(0xc0, s)

                let success := staticcall(gas(), 7, 0x80, 0x60, 0x80, 0x40)
                if iszero(success) {
                    revertWithMessage(27, "point multiplication failed")
                }
                t_x := mload(0x80)
                t_y := mload(add(0x80, 0x20))
            }

            function point_add(p1_x, p1_y, p2_x, p2_y) -> t_x, t_y {
                mstore(0x80, p1_x)
                mstore(0xa0, p1_y)
                mstore(0xc0, p2_x)
                mstore(0xe0, p2_y)

                let success := staticcall(gas(), 6, 0x80, 0x80, 0x80, 0x40)
                if iszero(success) {
                    revertWithMessage(21, "point addition failed")
                }

                t_x := mload(0x80)
                t_y := mload(add(0x80, 0x20))
            }

            function point_sub(p1_x, p1_y, p2_x, p2_y) -> t_x, t_y {
                mstore(0x80, p1_x)
                mstore(0xa0, p1_y)
                mstore(0xc0, p2_x)
                mstore(0xe0, sub(Q_MOD, p2_y))

                let success := staticcall(gas(), 6, 0x80, 0x80, 0x80, 0x40)
                if iszero(success) {
                    revertWithMessage(24, "point subtraction failed")
                }

                t_x := mload(0x80)
                t_y := mload(add(0x80, 0x20))
            }

            function pairing_check(p1_x, p1_y, is_zero_commitment) -> res {
                mstore(0x80, p1_x)
                mstore(0xa0, p1_y)
                mstore(0xc0, VK_G2_ELEMENT_0_X1)
                mstore(0xe0, VK_G2_ELEMENT_0_X2)
                mstore(0x100, VK_G2_ELEMENT_0_Y1)
                mstore(0x120, VK_G2_ELEMENT_0_Y2)
                mstore(0x140, mload(MEM_PROOF_COMMITMENT_3_G1_X))
                mstore(0x160, mload(MEM_PROOF_COMMITMENT_3_G1_Y))
                if iszero(is_zero_commitment) {
                    mstore(0x160, sub(Q_MOD, mload(MEM_PROOF_COMMITMENT_3_G1_Y)))
                }
                mstore(0x180, VK_G2_ELEMENT_1_X1)
                mstore(0x1a0, VK_G2_ELEMENT_1_X2)
                mstore(0x1c0, VK_G2_ELEMENT_1_Y1)
                mstore(0x1e0, VK_G2_ELEMENT_1_Y2)

                let success := staticcall(gas(), 8, 0x80, mul(12, 0x20), 0x80, 0x20)

                if iszero(success) {
                    revertWithMessage(20, "pairing check failed")
                }
                res := mload(0x80)
            }

            function revertWithMessage(len, reason) {

                mstore(0x80, 0x08c379a000000000000000000000000000000000000000000000000000000000)

                mstore(0x84, 0x0000000000000000000000000000000000000000000000000000000000000020)

                mstore(0xa4, len)

                mstore(0xc4, reason)

                revert(0x80, 0x64)
            }

            function modexp(value, power) -> res {
                mstore(0x00, 0x20)
                mstore(0x20, 0x20)
                mstore(0x40, 0x20)
                mstore(0x60, value)
                mstore(0x80, power)
                mstore(0xa0, R_MOD)
                if iszero(staticcall(gas(), 5, 0, 0xc0, 0x00, 0x20)) {
                    revertWithMessage(24, "modexp precompile failed")
                }
                res := mload(0x00)
            }
        }
    }

       receive() external payable {

       }

}
