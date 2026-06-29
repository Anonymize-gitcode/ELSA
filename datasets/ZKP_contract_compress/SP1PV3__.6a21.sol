pragma solidity ^0.8.0;

contract PlonkVerifier {

    function Verify(bytes calldata proof, uint256[] calldata public_inputs)
        public
        view
        returns (bool success)
    {
        assembly {
            let mem := mload(0x40)
            let freeMem := add(mem, STATE_LAST_MEM)

            check_number_of_public_inputs(public_inputs.length)
            check_inputs_size(public_inputs.length, public_inputs.offset)
            check_proof_size(proof.length)
            check_proof_openings_size(proof.offset)

            let prev_challenge_non_reduced
            prev_challenge_non_reduced :=
                derive_gamma(proof.offset, public_inputs.length, public_inputs.offset)
            prev_challenge_non_reduced := derive_beta(prev_challenge_non_reduced)
            prev_challenge_non_reduced := derive_alpha(proof.offset, prev_challenge_non_reduced)
            derive_zeta(proof.offset, prev_challenge_non_reduced)

            let zeta := mload(add(mem, STATE_ZETA))
            let zeta_power_n_minus_one :=
                addmod(pow(zeta, VK_DOMAIN_SIZE, freeMem), sub(R_MOD, 1), R_MOD)
            mstore(add(mem, STATE_ZETA_POWER_N_MINUS_ONE), zeta_power_n_minus_one)

            let l_pi := sum_pi_wo_api_commit(public_inputs.offset, public_inputs.length, freeMem)
            let l_pi_commit := sum_pi_commit(proof.offset, public_inputs.length, freeMem)
            l_pi := addmod(l_pi_commit, l_pi, R_MOD)
            mstore(add(mem, STATE_PI), l_pi)

            compute_alpha_square_lagrange_0()
            compute_opening_linearised_polynomial(proof.offset)
            fold_h(proof.offset)
            compute_commitment_linearised_polynomial(proof.offset)
            compute_gamma_kzg(proof.offset)
            fold_state(proof.offset)
            batch_verify_multi_points(proof.offset)

            success := mload(add(mem, STATE_SUCCESS))

            function error_nb_public_inputs() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x1d)
                mstore(add(ptError, 0x44), "wrong number of public inputs")
                revert(ptError, 0x64)
            }

            function error_mod_exp() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0xc)
                mstore(add(ptError, 0x44), "error mod exp")
                revert(ptError, 0x64)
            }

            function error_ec_op() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x12)
                mstore(add(ptError, 0x44), "error ec operation")
                revert(ptError, 0x64)
            }

            function error_inputs_size() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x18)
                mstore(add(ptError, 0x44), "inputs are bigger than r")
                revert(ptError, 0x64)
            }

            function error_proof_size() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x10)
                mstore(add(ptError, 0x44), "wrong proof size")
                revert(ptError, 0x64)
            }

            function error_proof_openings_size() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x16)
                mstore(add(ptError, 0x44), "openings bigger than r")
                revert(ptError, 0x64)
            }

            function error_pairing() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0xd)
                mstore(add(ptError, 0x44), "error pairing")
                revert(ptError, 0x64)
            }

            function error_verify() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0xc)
                mstore(add(ptError, 0x44), "error verify")
                revert(ptError, 0x64)
            }

            function error_random_generation() {
                let ptError := mload(0x40)
                mstore(ptError, ERROR_STRING_ID)
                mstore(add(ptError, 0x4), 0x20)
                mstore(add(ptError, 0x24), 0x14)
                mstore(add(ptError, 0x44), "error random gen kzg")
                revert(ptError, 0x64)
            }

            function check_number_of_public_inputs(s) {
                if iszero(eq(s, VK_NB_PUBLIC_INPUTS)) { error_nb_public_inputs() }
            }

            function check_inputs_size(s, p) {
                for { let i } lt(i, s) { i := add(i, 1) } {
                    if gt(calldataload(p), R_MOD_MINUS_ONE) { error_inputs_size() }
                    p := add(p, 0x20)
                }
            }

            function check_proof_size(actual_proof_size) {
                let expected_proof_size := add(FIXED_PROOF_SIZE, mul(VK_NB_CUSTOM_GATES, 0x60))
                if iszero(eq(actual_proof_size, expected_proof_size)) { error_proof_size() }
            }

            function check_proof_openings_size(aproof) {

                let p := add(aproof, PROOF_L_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) { error_proof_openings_size() }

                p := add(aproof, PROOF_R_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) { error_proof_openings_size() }

                p := add(aproof, PROOF_O_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) { error_proof_openings_size() }

                p := add(aproof, PROOF_S1_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) { error_proof_openings_size() }

                p := add(aproof, PROOF_S2_AT_ZETA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) { error_proof_openings_size() }

                p := add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA)
                if gt(calldataload(p), R_MOD_MINUS_ONE) { error_proof_openings_size() }

                p := add(aproof, PROOF_OPENING_QCP_AT_ZETA)
                for { let i := 0 } lt(i, VK_NB_CUSTOM_GATES) { i := add(i, 1) } {
                    if gt(calldataload(p), R_MOD_MINUS_ONE) { error_proof_openings_size() }
                    p := add(p, 0x20)
                }
            }

            function derive_gamma(aproof, nb_pi, pi) -> gamma_not_reduced {
                let state := mload(0x40)
                let mPtr := add(state, STATE_LAST_MEM)

                mstore(mPtr, FS_GAMMA)

                mstore(add(mPtr, 0x20), VK_S1_COM_X)
                mstore(add(mPtr, 0x40), VK_S1_COM_Y)
                mstore(add(mPtr, 0x60), VK_S2_COM_X)
                mstore(add(mPtr, 0x80), VK_S2_COM_Y)
                mstore(add(mPtr, 0xa0), VK_S3_COM_X)
                mstore(add(mPtr, 0xc0), VK_S3_COM_Y)
                mstore(add(mPtr, 0xe0), VK_QL_COM_X)
                mstore(add(mPtr, 0x100), VK_QL_COM_Y)
                mstore(add(mPtr, 0x120), VK_QR_COM_X)
                mstore(add(mPtr, 0x140), VK_QR_COM_Y)
                mstore(add(mPtr, 0x160), VK_QM_COM_X)
                mstore(add(mPtr, 0x180), VK_QM_COM_Y)
                mstore(add(mPtr, 0x1a0), VK_QO_COM_X)
                mstore(add(mPtr, 0x1c0), VK_QO_COM_Y)
                mstore(add(mPtr, 0x1e0), VK_QK_COM_X)
                mstore(add(mPtr, 0x200), VK_QK_COM_Y)

                mstore(add(mPtr, 0x220), VK_QCP_0_X)
                mstore(add(mPtr, 0x240), VK_QCP_0_Y)

                let _mPtr := add(mPtr, 0x260)
                let size_pi_in_bytes := mul(nb_pi, 0x20)
                calldatacopy(_mPtr, pi, size_pi_in_bytes)
                _mPtr := add(_mPtr, size_pi_in_bytes)

                let size_commitments_lro_in_bytes := 0xc0
                calldatacopy(_mPtr, aproof, size_commitments_lro_in_bytes)
                _mPtr := add(_mPtr, size_commitments_lro_in_bytes)

                let size := add(0x2c5, size_pi_in_bytes)

                size := add(size, mul(VK_NB_CUSTOM_GATES, 0x40))
                let l_success := staticcall(gas(), SHA2, add(mPtr, 0x1b), size, mPtr, 0x20)
                if iszero(l_success) { error_verify() }
                gamma_not_reduced := mload(mPtr)
                mstore(add(state, STATE_GAMMA), mod(gamma_not_reduced, R_MOD))
            }

            function derive_beta(gamma_not_reduced) -> beta_not_reduced {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)

                mstore(mPtr, FS_BETA)
                mstore(add(mPtr, 0x20), gamma_not_reduced)
                let l_success := staticcall(gas(), SHA2, add(mPtr, 0x1c), 0x24, mPtr, 0x20)
                if iszero(l_success) { error_verify() }
                beta_not_reduced := mload(mPtr)
                mstore(add(state, STATE_BETA), mod(beta_not_reduced, R_MOD))
            }

            function derive_alpha(aproof, beta_not_reduced) -> alpha_not_reduced {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)
                let full_size := 0x65

                mstore(mPtr, FS_ALPHA)
                let _mPtr := add(mPtr, 0x20)
                mstore(_mPtr, beta_not_reduced)
                _mPtr := add(_mPtr, 0x20)

                let proof_bsb_commitments := add(aproof, PROOF_BSB_COMMITMENTS)
                let size_bsb_commitments := mul(0x40, VK_NB_CUSTOM_GATES)
                calldatacopy(_mPtr, proof_bsb_commitments, size_bsb_commitments)
                _mPtr := add(_mPtr, size_bsb_commitments)
                full_size := a