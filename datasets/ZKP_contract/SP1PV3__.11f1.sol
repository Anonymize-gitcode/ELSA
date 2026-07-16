pragma solidity ^0.8.0;

contract PlonkVerifier {
    uint256 private constant R_MOD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 private constant R_MOD_MINUS_ONE =
        21888242871839275222246405745257275088548364400416034343698204186575808495616;
    uint256 private constant P_MOD =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    uint256 private constant G2_SRS_0_X_0 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 private constant G2_SRS_0_X_1 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 private constant G2_SRS_0_Y_0 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 private constant G2_SRS_0_Y_1 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;

    uint256 private constant G2_SRS_1_X_0 =
        15805639136721018565402881920352193254830339253282065586954346329754995870280;
    uint256 private constant G2_SRS_1_X_1 =
        19089565590083334368588890253123139704298730990782503769911324779715431555531;
    uint256 private constant G2_SRS_1_Y_0 =
        9779648407879205346559610309258181044130619080926897934572699915909528404984;
    uint256 private constant G2_SRS_1_Y_1 =
        6779728121489434657638426458390319301070371227460768374343986326751507916979;

    uint256 private constant G1_SRS_X =
        14312776538779914388377568895031746459131577658076416373430523308756343304251;
    uint256 private constant G1_SRS_Y =
        11763105256161367503191792604679297387056316997144156930871823008787082098465;

    uint256 private constant VK_NB_PUBLIC_INPUTS = 2;
    uint256 private constant VK_DOMAIN_SIZE = 16777216;
    uint256 private constant VK_INV_DOMAIN_SIZE =
        21888241567198334088790460357988866238279339518792980768180410072331574733841;
    uint256 private constant VK_OMEGA =
        5709868443893258075976348696661355716898495876243883251619397131511003808859;
    uint256 private constant VK_QL_COM_X =
        6698926252499501918627049539857227069908963353308522713401817428479361568440;
    uint256 private constant VK_QL_COM_Y =
        390398004416183979452133282904065487059356531982837080656872214854553489350;
    uint256 private constant VK_QR_COM_X =
        15880456667347413803865543437928881464825011023890441259779169206403913363151;
    uint256 private constant VK_QR_COM_Y =
        3767941190808440189902161405604124601331914695906424222482338276374206831132;
    uint256 private constant VK_QM_COM_X =
        5880611536603228408869722577745139096541545452210666651972026582265463007511;
    uint256 private constant VK_QM_COM_Y =
        1224143639924163872305752448189325623163513756607992331286640139697358890946;
    uint256 private constant VK_QO_COM_X =
        10784511595954287406993173499667136603239479748310285717260107338983244276060;
    uint256 private constant VK_QO_COM_Y =
        18906558344705317932195383600423433585385784884571943386801247393368669782537;
    uint256 private constant VK_QK_COM_X =
        8180704256866827100696103553863514644647533905025339515563713328928483788032;
    uint256 private constant VK_QK_COM_Y =
        747878568663636575539538121119102874439625248674411200631787363393534765215;

    uint256 private constant VK_S1_COM_X =
        15880661300853021639231473742380264628736914186438251569837407188944320716554;
    uint256 private constant VK_S1_COM_Y =
        17368402498745842963461937676623436150527636742807769735472062133579682935390;

    uint256 private constant VK_S2_COM_X =
        17774064061947492896572463203478116570275709112580707484534909374676668977524;
    uint256 private constant VK_S2_COM_Y =
        10372960929593342938703206496348658292612468496655535789104353649836524032299;

    uint256 private constant VK_S3_COM_X =
        21131795236225698179116006663026974130944823263770762203882565449801882913775;
    uint256 private constant VK_S3_COM_Y =
        6122699356523015511637022172421089077159502502652656594712329899009208296070;

    uint256 private constant VK_COSET_SHIFT = 5;

    uint256 private constant VK_QCP_0_X =
        9522352021536039370701096527024757579826875694034309808870403911322444208289;
    uint256 private constant VK_QCP_0_Y =
        18911718139779028078468950841548487462498208718101892018848709759471198128993;

    uint256 private constant VK_INDEX_COMMIT_API_0 = 8957791;
    uint256 private constant VK_NB_CUSTOM_GATES = 1;

    uint256 private constant FIXED_PROOF_SIZE = 0x300;

    uint256 private constant PROOF_L_COM_X = 0x0;
    uint256 private constant PROOF_L_COM_Y = 0x20;
    uint256 private constant PROOF_R_COM_X = 0x40;
    uint256 private constant PROOF_R_COM_Y = 0x60;
    uint256 private constant PROOF_O_COM_X = 0x80;
    uint256 private constant PROOF_O_COM_Y = 0xa0;

    uint256 private constant PROOF_H_0_COM_X = 0xc0;
    uint256 private constant PROOF_H_0_COM_Y = 0xe0;
    uint256 private constant PROOF_H_1_COM_X = 0x100;
    uint256 private constant PROOF_H_1_COM_Y = 0x120;
    uint256 private constant PROOF_H_2_COM_X = 0x140;
    uint256 private constant PROOF_H_2_COM_Y = 0x160;

    uint256 private constant PROOF_L_AT_ZETA = 0x180;
    uint256 private constant PROOF_R_AT_ZETA = 0x1a0;
    uint256 private constant PROOF_O_AT_ZETA = 0x1c0;

    uint256 private constant PROOF_S1_AT_ZETA = 0x1e0;
    uint256 private constant PROOF_S2_AT_ZETA = 0x200;

    uint256 private constant PROOF_GRAND_PRODUCT_COMMITMENT_X = 0x220;
    uint256 private constant PROOF_GRAND_PRODUCT_COMMITMENT_Y = 0x240;

    uint256 private constant PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA = 0x260;

    uint256 private constant PROOF_BATCH_OPENING_AT_ZETA_X = 0x280;
    uint256 private constant PROOF_BATCH_OPENING_AT_ZETA_Y = 0x2a0;

    uint256 private constant PROOF_OPENING_AT_ZETA_OMEGA_X = 0x2c0;
    uint256 private constant PROOF_OPENING_AT_ZETA_OMEGA_Y = 0x2e0;

    uint256 private constant PROOF_OPENING_QCP_AT_ZETA = 0x300;
    uint256 private constant PROOF_BSB_COMMITMENTS = 0x320;

    uint256 private constant STATE_ALPHA = 0x0;
    uint256 private constant STATE_BETA = 0x20;
    uint256 private constant STATE_GAMMA = 0x40;
    uint256 private constant STATE_ZETA = 0x60;
    uint256 private constant STATE_ALPHA_SQUARE_LAGRANGE_0 = 0x80;
    uint256 private constant STATE_FOLDED_H_X = 0xa0;
    uint256 private constant STATE_FOLDED_H_Y = 0xc0;
    uint256 private constant STATE_LINEARISED_POLYNOMIAL_X = 0xe0;
    uint256 private constant STATE_LINEARISED_POLYNOMIAL_Y = 0x100;
    uint256 private constant STATE_OPENING_LINEARISED_POLYNOMIAL_ZETA = 0x120;
    uint256 private constant STATE_FOLDED_CLAIMED_VALUES = 0x140;
    uint256 private constant STATE_FOLDED_DIGESTS_X = 0x160;
    uint256 private constant STATE_FOLDED_DIGESTS_Y = 0x180;
    uint256 private constant STATE_PI = 0x1a0;
    uint256 private constant STATE_ZETA_POWER_N_MINUS_ONE = 0x1c0;
    uint256 private constant STATE_GAMMA_KZG = 0x1e0;
    uint256 private constant STATE_SUCCESS = 0x200;
    uint256 private constant STATE_CHECK_VAR = 0x220;
    uint256 private constant STATE_LAST_MEM = 0x240;

    uint256 private constant FS_ALPHA = 0x616C706861;
    uint256 private constant FS_BETA = 0x62657461;
    uint256 private constant FS_GAMMA = 0x67616d6d61;
    uint256 private constant FS_ZETA = 0x7a657461;
    uint256 private constant FS_GAMMA_KZG = 0x67616d6d61;

    uint256 private constant ERROR_STRING_ID =
        0x08c379a000000000000000000000000000000000000000000000000000000000;

    uint256 private constant HASH_FR_BB = 340282366920938463463374607431768211456;
    uint256 private constant HASH_FR_ZERO_UINT256 = 0;
    uint8 private constant HASH_FR_LEN_IN_BYTES = 48;
    uint8 private constant HASH_FR_SIZE_DOMAIN = 11;
    uint8 private constant HASH_FR_ONE = 1;
    uint8 private constant HASH_FR_TWO = 2;

    uint8 private constant SHA2 = 0x2;
    uint8 private constant MOD_EXP = 0x5;
    uint8 private constant EC_ADD = 0x6;
    uint8 private constant EC_MUL = 0x7;
    uint8 private constant EC_PAIR = 0x8;

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
                full_size := add(full_size, size_bsb_commitments)

                calldatacopy(_mPtr, add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_X), 0x40)
                let l_success := staticcall(gas(), SHA2, add(mPtr, 0x1b), full_size, mPtr, 0x20)
                if iszero(l_success) { error_verify() }

                alpha_not_reduced := mload(mPtr)
                mstore(add(state, STATE_ALPHA), mod(alpha_not_reduced, R_MOD))
            }

            function derive_zeta(aproof, alpha_not_reduced) {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)

                mstore(mPtr, FS_ZETA)
                mstore(add(mPtr, 0x20), alpha_not_reduced)
                calldatacopy(add(mPtr, 0x40), add(aproof, PROOF_H_0_COM_X), 0xc0)
                let l_success := staticcall(gas(), SHA2, add(mPtr, 0x1c), 0xe4, mPtr, 0x20)
                if iszero(l_success) { error_verify() }
                let zeta_not_reduced := mload(mPtr)
                mstore(add(state, STATE_ZETA), mod(zeta_not_reduced, R_MOD))
            }

            function sum_pi_wo_api_commit(ins, n, mPtr) -> pi_wo_commit {
                let state := mload(0x40)
                let z := mload(add(state, STATE_ZETA))
                let zpnmo := mload(add(state, STATE_ZETA_POWER_N_MINUS_ONE))

                let li := mPtr
                batch_compute_lagranges_at_z(z, zpnmo, n, li)

                let tmp := 0
                for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                    tmp := mulmod(mload(li), calldataload(ins), R_MOD)
                    pi_wo_commit := addmod(pi_wo_commit, tmp, R_MOD)
                    li := add(li, 0x20)
                    ins := add(ins, 0x20)
                }
            }

            function batch_compute_lagranges_at_z(z, zpnmo, n_pub, mPtr) {
                let zn := mulmod(zpnmo, VK_INV_DOMAIN_SIZE, R_MOD)

                let _w := 1
                let _mPtr := mPtr
                for { let i := 0 } lt(i, n_pub) { i := add(i, 1) } {
                    mstore(_mPtr, addmod(z, sub(R_MOD, _w), R_MOD))
                    _w := mulmod(_w, VK_OMEGA, R_MOD)
                    _mPtr := add(_mPtr, 0x20)
                }
                batch_invert(mPtr, n_pub, _mPtr)
                _mPtr := mPtr
                _w := 1
                for { let i := 0 } lt(i, n_pub) { i := add(i, 1) } {
                    mstore(_mPtr, mulmod(mulmod(mload(_mPtr), zn, R_MOD), _w, R_MOD))
                    _mPtr := add(_mPtr, 0x20)
                    _w := mulmod(_w, VK_OMEGA, R_MOD)
                }
            }

            function batch_invert(ins, nb_ins, mPtr) {
                mstore(mPtr, 1)
                let offset := 0
                for { let i := 0 } lt(i, nb_ins) { i := add(i, 1) } {
                    let prev := mload(add(mPtr, offset))
                    let cur := mload(add(ins, offset))
                    cur := mulmod(prev, cur, R_MOD)
                    offset := add(offset, 0x20)
                    mstore(add(mPtr, offset), cur)
                }
                ins := add(ins, sub(offset, 0x20))
                mPtr := add(mPtr, offset)
                let inv := pow(mload(mPtr), sub(R_MOD, 2), add(mPtr, 0x20))
                for { let i := 0 } lt(i, nb_ins) { i := add(i, 1) } {
                    mPtr := sub(mPtr, 0x20)
                    let tmp := mload(ins)
                    let cur := mulmod(inv, mload(mPtr), R_MOD)
                    mstore(ins, cur)
                    inv := mulmod(inv, tmp, R_MOD)
                    ins := sub(ins, 0x20)
                }
            }

            function sum_pi_commit(aproof, nb_public_inputs, mPtr) -> pi_commit {
                let state := mload(0x40)
                let z := mload(add(state, STATE_ZETA))
                let zpnmo := mload(add(state, STATE_ZETA_POWER_N_MINUS_ONE))

                let p := add(aproof, PROOF_BSB_COMMITMENTS)

                let h_fr, ith_lagrange

                h_fr := hash_fr(calldataload(p), calldataload(add(p, 0x20)), mPtr)
                ith_lagrange :=
                    compute_ith_lagrange_at_z(
                        z, zpnmo, add(nb_public_inputs, VK_INDEX_COMMIT_API_0), mPtr
                    )
                pi_commit := addmod(pi_commit, mulmod(h_fr, ith_lagrange, R_MOD), R_MOD)
            }

            function compute_ith_lagrange_at_z(z, zpnmo, i, mPtr) -> res {
                let w := pow(VK_OMEGA, i, mPtr)
                i := addmod(z, sub(R_MOD, w), R_MOD)
                w := mulmod(w, VK_INV_DOMAIN_SIZE, R_MOD)
                i := pow(i, sub(R_MOD, 2), mPtr)
                w := mulmod(w, i, R_MOD)
                res := mulmod(w, zpnmo, R_MOD)
            }

            function hash_fr(x, y, mPtr) -> res {

                mstore(mPtr, HASH_FR_ZERO_UINT256)
                mstore(add(mPtr, 0x20), HASH_FR_ZERO_UINT256)

                mstore(add(mPtr, 0x40), x)
                mstore(add(mPtr, 0x60), y)

                mstore8(add(mPtr, 0x80), 0)
                mstore8(add(mPtr, 0x81), HASH_FR_LEN_IN_BYTES)
                mstore8(add(mPtr, 0x82), 0)

                mstore8(add(mPtr, 0x83), 0x42)
                mstore8(add(mPtr, 0x84), 0x53)
                mstore8(add(mPtr, 0x85), 0x42)
                mstore8(add(mPtr, 0x86), 0x32)
                mstore8(add(mPtr, 0x87), 0x32)
                mstore8(add(mPtr, 0x88), 0x2d)
                mstore8(add(mPtr, 0x89), 0x50)
                mstore8(add(mPtr, 0x8a), 0x6c)
                mstore8(add(mPtr, 0x8b), 0x6f)
                mstore8(add(mPtr, 0x8c), 0x6e)
                mstore8(add(mPtr, 0x8d), 0x6b)

                mstore8(add(mPtr, 0x8e), HASH_FR_SIZE_DOMAIN)

                let l_success := staticcall(gas(), SHA2, mPtr, 0x8f, mPtr, 0x20)
                if iszero(l_success) { error_verify() }

                let b0 := mload(mPtr)

                mstore8(add(mPtr, 0x20), HASH_FR_ONE)

                mstore8(add(mPtr, 0x21), 0x42)
                mstore8(add(mPtr, 0x22), 0x53)
                mstore8(add(mPtr, 0x23), 0x42)
                mstore8(add(mPtr, 0x24), 0x32)
                mstore8(add(mPtr, 0x25), 0x32)
                mstore8(add(mPtr, 0x26), 0x2d)
                mstore8(add(mPtr, 0x27), 0x50)
                mstore8(add(mPtr, 0x28), 0x6c)
                mstore8(add(mPtr, 0x29), 0x6f)
                mstore8(add(mPtr, 0x2a), 0x6e)
                mstore8(add(mPtr, 0x2b), 0x6b)

                mstore8(add(mPtr, 0x2c), HASH_FR_SIZE_DOMAIN)
                l_success := staticcall(gas(), SHA2, mPtr, 0x2d, mPtr, 0x20)
                if iszero(l_success) { error_verify() }

                mstore(add(mPtr, 0x20), xor(mload(mPtr), b0))
                mstore8(add(mPtr, 0x40), HASH_FR_TWO)

                mstore8(add(mPtr, 0x41), 0x42)
                mstore8(add(mPtr, 0x42), 0x53)
                mstore8(add(mPtr, 0x43), 0x42)
                mstore8(add(mPtr, 0x44), 0x32)
                mstore8(add(mPtr, 0x45), 0x32)
                mstore8(add(mPtr, 0x46), 0x2d)
                mstore8(add(mPtr, 0x47), 0x50)
                mstore8(add(mPtr, 0x48), 0x6c)
                mstore8(add(mPtr, 0x49), 0x6f)
                mstore8(add(mPtr, 0x4a), 0x6e)
                mstore8(add(mPtr, 0x4b), 0x6b)

                mstore8(add(mPtr, 0x4c), HASH_FR_SIZE_DOMAIN)

                let offset := add(mPtr, 0x20)
                l_success := staticcall(gas(), SHA2, offset, 0x2d, offset, 0x20)
                if iszero(l_success) { error_verify() }

                res := mulmod(mload(mPtr), HASH_FR_BB, R_MOD)
                let b1 := shr(128, mload(add(mPtr, 0x20)))
                res := addmod(res, b1, R_MOD)
            }

            function compute_alpha_square_lagrange_0() {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)

                let res := mload(add(state, STATE_ZETA_POWER_N_MINUS_ONE))
                let den := addmod(mload(add(state, STATE_ZETA)), sub(R_MOD, 1), R_MOD)
                den := pow(den, sub(R_MOD, 2), mPtr)
                den := mulmod(den, VK_INV_DOMAIN_SIZE, R_MOD)
                res := mulmod(den, res, R_MOD)

                let l_alpha := mload(add(state, STATE_ALPHA))
                res := mulmod(res, l_alpha, R_MOD)
                res := mulmod(res, l_alpha, R_MOD)
                mstore(add(state, STATE_ALPHA_SQUARE_LAGRANGE_0), res)
            }

            function batch_verify_multi_points(aproof) {
                let state := mload(0x40)
                let mPtr := add(state, STATE_LAST_MEM)

                mstore(mPtr, mload(add(state, STATE_FOLDED_DIGESTS_X)))
                mstore(add(mPtr, 0x20), mload(add(state, STATE_FOLDED_DIGESTS_Y)))
                mstore(add(mPtr, 0x40), calldataload(add(aproof, PROOF_BATCH_OPENING_AT_ZETA_X)))
                mstore(add(mPtr, 0x60), calldataload(add(aproof, PROOF_BATCH_OPENING_AT_ZETA_Y)))
                mstore(add(mPtr, 0x80), calldataload(add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_X)))
                mstore(add(mPtr, 0xa0), calldataload(add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_Y)))
                mstore(add(mPtr, 0xc0), calldataload(add(aproof, PROOF_OPENING_AT_ZETA_OMEGA_X)))
                mstore(add(mPtr, 0xe0), calldataload(add(aproof, PROOF_OPENING_AT_ZETA_OMEGA_Y)))
                mstore(add(mPtr, 0x100), mload(add(state, STATE_ZETA)))
                mstore(add(mPtr, 0x120), mload(add(state, STATE_GAMMA_KZG)))
                let random := staticcall(gas(), SHA2, mPtr, 0x140, mPtr, 0x20)
                if iszero(random) { error_random_generation() }
                random := mod(mload(mPtr), R_MOD)

                let folded_quotients := mPtr
                mPtr := add(folded_quotients, 0x40)
                mstore(folded_quotients, calldataload(add(aproof, PROOF_BATCH_OPENING_AT_ZETA_X)))
                mstore(
                    add(folded_quotients, 0x20),
                    calldataload(add(aproof, PROOF_BATCH_OPENING_AT_ZETA_Y))
                )
                point_acc_mul_calldata(
                    folded_quotients, add(aproof, PROOF_OPENING_AT_ZETA_OMEGA_X), random, mPtr
                )

                let folded_digests := add(state, STATE_FOLDED_DIGESTS_X)
                point_acc_mul_calldata(
                    folded_digests, add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_X), random, mPtr
                )

                let folded_evals := add(state, STATE_FOLDED_CLAIMED_VALUES)
                fr_acc_mul_calldata(
                    folded_evals, add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA), random
                )

                let folded_evals_commit := mPtr
                mPtr := add(folded_evals_commit, 0x40)
                mstore(folded_evals_commit, G1_SRS_X)
                mstore(add(folded_evals_commit, 0x20), G1_SRS_Y)
                mstore(add(folded_evals_commit, 0x40), mload(folded_evals))
                let check_staticcall :=
                    staticcall(gas(), 7, folded_evals_commit, 0x60, folded_evals_commit, 0x40)
                if iszero(check_staticcall) { error_verify() }

                let folded_evals_commit_y := add(folded_evals_commit, 0x20)
                mstore(folded_evals_commit_y, sub(P_MOD, mload(folded_evals_commit_y)))
                point_add(folded_digests, folded_digests, folded_evals_commit, mPtr)

                let folded_points_quotients := mPtr
                mPtr := add(mPtr, 0x40)
                point_mul_calldata(
                    folded_points_quotients,
                    add(aproof, PROOF_BATCH_OPENING_AT_ZETA_X),
                    mload(add(state, STATE_ZETA)),
                    mPtr
                )
                let zeta_omega := mulmod(mload(add(state, STATE_ZETA)), VK_OMEGA, R_MOD)
                random := mulmod(random, zeta_omega, R_MOD)
                point_acc_mul_calldata(
                    folded_points_quotients,
                    add(aproof, PROOF_OPENING_AT_ZETA_OMEGA_X),
                    random,
                    mPtr
                )

                point_add(folded_digests, folded_digests, folded_points_quotients, mPtr)

                let folded_quotients_y := add(folded_quotients, 0x20)
                mstore(folded_quotients_y, sub(P_MOD, mload(folded_quotients_y)))

                mstore(mPtr, mload(folded_digests))

                mstore(add(mPtr, 0x20), mload(add(folded_digests, 0x20)))
                mstore(add(mPtr, 0x40), G2_SRS_0_X_0)
                mstore(add(mPtr, 0x60), G2_SRS_0_X_1)
                mstore(add(mPtr, 0x80), G2_SRS_0_Y_0)
                mstore(add(mPtr, 0xa0), G2_SRS_0_Y_1)
                mstore(add(mPtr, 0xc0), mload(folded_quotients))
                mstore(add(mPtr, 0xe0), mload(add(folded_quotients, 0x20)))
                mstore(add(mPtr, 0x100), G2_SRS_1_X_0)
                mstore(add(mPtr, 0x120), G2_SRS_1_X_1)
                mstore(add(mPtr, 0x140), G2_SRS_1_Y_0)
                mstore(add(mPtr, 0x160), G2_SRS_1_Y_1)
                check_pairing_kzg(mPtr)
            }

            function check_pairing_kzg(mPtr) {
                let state := mload(0x40)

                let l_success := staticcall(gas(), 8, mPtr, 0x180, 0x00, 0x20)
                if iszero(l_success) { error_pairing() }
                let res_pairing := mload(0x00)
                mstore(add(state, STATE_SUCCESS), res_pairing)
            }

            function fold_state(aproof) {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)
                let mPtr20 := add(mPtr, 0x20)
                let mPtr40 := add(mPtr, 0x40)

                let l_gamma_kzg := mload(add(state, STATE_GAMMA_KZG))
                let acc_gamma := l_gamma_kzg
                let state_folded_digests := add(state, STATE_FOLDED_DIGESTS_X)

                mstore(state_folded_digests, mload(add(state, STATE_LINEARISED_POLYNOMIAL_X)))
                mstore(
                    add(state, STATE_FOLDED_DIGESTS_Y),
                    mload(add(state, STATE_LINEARISED_POLYNOMIAL_Y))
                )
                mstore(
                    add(state, STATE_FOLDED_CLAIMED_VALUES),
                    mload(add(state, STATE_OPENING_LINEARISED_POLYNOMIAL_ZETA))
                )

                point_acc_mul_calldata(
                    state_folded_digests, add(aproof, PROOF_L_COM_X), acc_gamma, mPtr
                )
                fr_acc_mul_calldata(
                    add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_L_AT_ZETA), acc_gamma
                )

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                point_acc_mul_calldata(
                    state_folded_digests, add(aproof, PROOF_R_COM_X), acc_gamma, mPtr
                )
                fr_acc_mul_calldata(
                    add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_R_AT_ZETA), acc_gamma
                )

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                point_acc_mul_calldata(
                    state_folded_digests, add(aproof, PROOF_O_COM_X), acc_gamma, mPtr
                )
                fr_acc_mul_calldata(
                    add(state, STATE_FOLDED_CLAIMED_VALUES), add(aproof, PROOF_O_AT_ZETA), acc_gamma
                )

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                mstore(mPtr, VK_S1_COM_X)
                mstore(mPtr20, VK_S1_COM_Y)
                point_acc_mul(state_folded_digests, mPtr, acc_gamma, mPtr40)
                fr_acc_mul_calldata(
                    add(state, STATE_FOLDED_CLAIMED_VALUES),
                    add(aproof, PROOF_S1_AT_ZETA),
                    acc_gamma
                )

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                mstore(mPtr, VK_S2_COM_X)
                mstore(mPtr20, VK_S2_COM_Y)
                point_acc_mul(state_folded_digests, mPtr, acc_gamma, mPtr40)
                fr_acc_mul_calldata(
                    add(state, STATE_FOLDED_CLAIMED_VALUES),
                    add(aproof, PROOF_S2_AT_ZETA),
                    acc_gamma
                )
                let poqaz := add(aproof, PROOF_OPENING_QCP_AT_ZETA)

                acc_gamma := mulmod(acc_gamma, l_gamma_kzg, R_MOD)
                mstore(mPtr, VK_QCP_0_X)
                mstore(mPtr20, VK_QCP_0_Y)
                point_acc_mul(state_folded_digests, mPtr, acc_gamma, mPtr40)
                fr_acc_mul_calldata(add(state, STATE_FOLDED_CLAIMED_VALUES), poqaz, acc_gamma)
                poqaz := add(poqaz, 0x20)
            }

            function compute_gamma_kzg(aproof) {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)
                mstore(mPtr, FS_GAMMA_KZG)
                mstore(add(mPtr, 0x20), mload(add(state, STATE_ZETA)))
                mstore(add(mPtr, 0x40), mload(add(state, STATE_LINEARISED_POLYNOMIAL_X)))
                mstore(add(mPtr, 0x60), mload(add(state, STATE_LINEARISED_POLYNOMIAL_Y)))
                calldatacopy(add(mPtr, 0x80), add(aproof, PROOF_L_COM_X), 0xc0)
                mstore(add(mPtr, 0x140), VK_S1_COM_X)
                mstore(add(mPtr, 0x160), VK_S1_COM_Y)
                mstore(add(mPtr, 0x180), VK_S2_COM_X)
                mstore(add(mPtr, 0x1a0), VK_S2_COM_Y)

                let offset := 0x1c0

                mstore(add(mPtr, offset), VK_QCP_0_X)
                mstore(add(mPtr, add(offset, 0x20)), VK_QCP_0_Y)
                offset := add(offset, 0x40)
                mstore(
                    add(mPtr, offset), mload(add(state, STATE_OPENING_LINEARISED_POLYNOMIAL_ZETA))
                )
                mstore(add(mPtr, add(offset, 0x20)), calldataload(add(aproof, PROOF_L_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0x40)), calldataload(add(aproof, PROOF_R_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0x60)), calldataload(add(aproof, PROOF_O_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0x80)), calldataload(add(aproof, PROOF_S1_AT_ZETA)))
                mstore(add(mPtr, add(offset, 0xa0)), calldataload(add(aproof, PROOF_S2_AT_ZETA)))

                let _mPtr := add(mPtr, add(offset, 0xc0))

                let _poqaz := add(aproof, PROOF_OPENING_QCP_AT_ZETA)
                calldatacopy(_mPtr, _poqaz, mul(VK_NB_CUSTOM_GATES, 0x20))
                _mPtr := add(_mPtr, mul(VK_NB_CUSTOM_GATES, 0x20))

                mstore(_mPtr, calldataload(add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA)))

                let start_input := 0x1b
                let size_input := add(0x14, mul(VK_NB_CUSTOM_GATES, 3))
                size_input := add(0x5, mul(size_input, 0x20))
                let check_staticcall :=
                    staticcall(
                        gas(),
                        SHA2,
                        add(mPtr, start_input),
                        size_input,
                        add(state, STATE_GAMMA_KZG),
                        0x20
                    )
                if iszero(check_staticcall) { error_verify() }
                mstore(add(state, STATE_GAMMA_KZG), mod(mload(add(state, STATE_GAMMA_KZG)), R_MOD))
            }

            function compute_commitment_linearised_polynomial_ec(aproof, s1, s2) {
                let state := mload(0x40)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)

                mstore(mPtr, VK_QL_COM_X)
                mstore(add(mPtr, 0x20), VK_QL_COM_Y)
                point_mul(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    mPtr,
                    calldataload(add(aproof, PROOF_L_AT_ZETA)),
                    add(mPtr, 0x40)
                )

                mstore(mPtr, VK_QR_COM_X)
                mstore(add(mPtr, 0x20), VK_QR_COM_Y)
                point_acc_mul(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    mPtr,
                    calldataload(add(aproof, PROOF_R_AT_ZETA)),
                    add(mPtr, 0x40)
                )

                let rl :=
                    mulmod(
                        calldataload(add(aproof, PROOF_L_AT_ZETA)),
                        calldataload(add(aproof, PROOF_R_AT_ZETA)),
                        R_MOD
                    )
                mstore(mPtr, VK_QM_COM_X)
                mstore(add(mPtr, 0x20), VK_QM_COM_Y)
                point_acc_mul(add(state, STATE_LINEARISED_POLYNOMIAL_X), mPtr, rl, add(mPtr, 0x40))

                mstore(mPtr, VK_QO_COM_X)
                mstore(add(mPtr, 0x20), VK_QO_COM_Y)
                point_acc_mul(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    mPtr,
                    calldataload(add(aproof, PROOF_O_AT_ZETA)),
                    add(mPtr, 0x40)
                )

                mstore(mPtr, VK_QK_COM_X)
                mstore(add(mPtr, 0x20), VK_QK_COM_Y)
                point_add(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    mPtr,
                    add(mPtr, 0x40)
                )

                let qcp_opening_at_zeta := add(aproof, PROOF_OPENING_QCP_AT_ZETA)
                let bsb_commitments := add(aproof, PROOF_BSB_COMMITMENTS)
                for { let i := 0 } lt(i, VK_NB_CUSTOM_GATES) { i := add(i, 1) } {
                    mstore(mPtr, calldataload(bsb_commitments))
                    mstore(add(mPtr, 0x20), calldataload(add(bsb_commitments, 0x20)))
                    point_acc_mul(
                        add(state, STATE_LINEARISED_POLYNOMIAL_X),
                        mPtr,
                        calldataload(qcp_opening_at_zeta),
                        add(mPtr, 0x40)
                    )
                    qcp_opening_at_zeta := add(qcp_opening_at_zeta, 0x20)
                    bsb_commitments := add(bsb_commitments, 0x40)
                }

                mstore(mPtr, VK_S3_COM_X)
                mstore(add(mPtr, 0x20), VK_S3_COM_Y)
                point_acc_mul(add(state, STATE_LINEARISED_POLYNOMIAL_X), mPtr, s1, add(mPtr, 0x40))

                mstore(mPtr, calldataload(add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_X)))
                mstore(add(mPtr, 0x20), calldataload(add(aproof, PROOF_GRAND_PRODUCT_COMMITMENT_Y)))
                point_acc_mul(add(state, STATE_LINEARISED_POLYNOMIAL_X), mPtr, s2, add(mPtr, 0x40))

                point_add(
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    add(state, STATE_LINEARISED_POLYNOMIAL_X),
                    add(state, STATE_FOLDED_H_X),
                    mPtr
                )
            }

            function compute_commitment_linearised_polynomial(aproof) {
                let state := mload(0x40)
                let l_beta := mload(add(state, STATE_BETA))
                let l_gamma := mload(add(state, STATE_GAMMA))
                let l_zeta := mload(add(state, STATE_ZETA))
                let l_alpha := mload(add(state, STATE_ALPHA))

                let u :=
                    mulmod(calldataload(add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA)), l_beta, R_MOD)
                let v := mulmod(l_beta, calldataload(add(aproof, PROOF_S1_AT_ZETA)), R_MOD)
                v := addmod(v, calldataload(add(aproof, PROOF_L_AT_ZETA)), R_MOD)
                v := addmod(v, l_gamma, R_MOD)

                let w := mulmod(l_beta, calldataload(add(aproof, PROOF_S2_AT_ZETA)), R_MOD)
                w := addmod(w, calldataload(add(aproof, PROOF_R_AT_ZETA)), R_MOD)
                w := addmod(w, l_gamma, R_MOD)

                let s1 := mulmod(u, v, R_MOD)
                s1 := mulmod(s1, w, R_MOD)
                s1 := mulmod(s1, l_alpha, R_MOD)

                let coset_square := mulmod(VK_COSET_SHIFT, VK_COSET_SHIFT, R_MOD)
                let betazeta := mulmod(l_beta, l_zeta, R_MOD)
                u := addmod(betazeta, calldataload(add(aproof, PROOF_L_AT_ZETA)), R_MOD)
                u := addmod(u, l_gamma, R_MOD)

                v := mulmod(betazeta, VK_COSET_SHIFT, R_MOD)
                v := addmod(v, calldataload(add(aproof, PROOF_R_AT_ZETA)), R_MOD)
                v := addmod(v, l_gamma, R_MOD)

                w := mulmod(betazeta, coset_square, R_MOD)
                w := addmod(w, calldataload(add(aproof, PROOF_O_AT_ZETA)), R_MOD)
                w := addmod(w, l_gamma, R_MOD)

                let s2 := mulmod(u, v, R_MOD)
                s2 := mulmod(s2, w, R_MOD)
                s2 := sub(R_MOD, s2)
                s2 := mulmod(s2, l_alpha, R_MOD)
                s2 := addmod(s2, mload(add(state, STATE_ALPHA_SQUARE_LAGRANGE_0)), R_MOD)

                compute_commitment_linearised_polynomial_ec(aproof, s1, s2)
            }

            function fold_h(aproof) {
                let state := mload(0x40)
                let n_plus_two := add(VK_DOMAIN_SIZE, 2)
                let mPtr := add(mload(0x40), STATE_LAST_MEM)
                let zeta_power_n_plus_two := pow(mload(add(state, STATE_ZETA)), n_plus_two, mPtr)
                point_mul_calldata(
                    add(state, STATE_FOLDED_H_X),
                    add(aproof, PROOF_H_2_COM_X),
                    zeta_power_n_plus_two,
                    mPtr
                )
                point_add_calldata(
                    add(state, STATE_FOLDED_H_X),
                    add(state, STATE_FOLDED_H_X),
                    add(aproof, PROOF_H_1_COM_X),
                    mPtr
                )
                point_mul(
                    add(state, STATE_FOLDED_H_X),
                    add(state, STATE_FOLDED_H_X),
                    zeta_power_n_plus_two,
                    mPtr
                )
                point_add_calldata(
                    add(state, STATE_FOLDED_H_X),
                    add(state, STATE_FOLDED_H_X),
                    add(aproof, PROOF_H_0_COM_X),
                    mPtr
                )
                point_mul(
                    add(state, STATE_FOLDED_H_X),
                    add(state, STATE_FOLDED_H_X),
                    mload(add(state, STATE_ZETA_POWER_N_MINUS_ONE)),
                    mPtr
                )
                let folded_h_y := mload(add(state, STATE_FOLDED_H_Y))
                folded_h_y := sub(P_MOD, folded_h_y)
                mstore(add(state, STATE_FOLDED_H_Y), folded_h_y)
            }

            function compute_opening_linearised_polynomial(aproof) {
                let state := mload(0x40)

                let s1
                s1 :=
                    mulmod(
                        calldataload(add(aproof, PROOF_S1_AT_ZETA)),
                        mload(add(state, STATE_BETA)),
                        R_MOD
                    )
                s1 := addmod(s1, mload(add(state, STATE_GAMMA)), R_MOD)
                s1 := addmod(s1, calldataload(add(aproof, PROOF_L_AT_ZETA)), R_MOD)

                let s2
                s2 :=
                    mulmod(
                        calldataload(add(aproof, PROOF_S2_AT_ZETA)),
                        mload(add(state, STATE_BETA)),
                        R_MOD
                    )
                s2 := addmod(s2, mload(add(state, STATE_GAMMA)), R_MOD)
                s2 := addmod(s2, calldataload(add(aproof, PROOF_R_AT_ZETA)), R_MOD)

                let o
                o :=
                    addmod(
                        calldataload(add(aproof, PROOF_O_AT_ZETA)),
                        mload(add(state, STATE_GAMMA)),
                        R_MOD
                    )

                s1 := mulmod(s1, s2, R_MOD)
                s1 := mulmod(s1, o, R_MOD)
                s1 := mulmod(s1, mload(add(state, STATE_ALPHA)), R_MOD)
                s1 :=
                    mulmod(s1, calldataload(add(aproof, PROOF_GRAND_PRODUCT_AT_ZETA_OMEGA)), R_MOD)

                s1 := addmod(s1, mload(add(state, STATE_PI)), R_MOD)
                s2 := mload(add(state, STATE_ALPHA_SQUARE_LAGRANGE_0))
                s2 := sub(R_MOD, s2)
                s1 := addmod(s1, s2, R_MOD)
                s1 := sub(R_MOD, s1)

                mstore(add(state, STATE_OPENING_LINEARISED_POLYNOMIAL_ZETA), s1)
            }

            function point_add(dst, p, q, mPtr) {
                mstore(mPtr, mload(p))
                mstore(add(mPtr, 0x20), mload(add(p, 0x20)))
                mstore(add(mPtr, 0x40), mload(q))
                mstore(add(mPtr, 0x60), mload(add(q, 0x20)))
                let l_success := staticcall(gas(), EC_ADD, mPtr, 0x80, dst, 0x40)
                if iszero(l_success) { error_ec_op() }
            }

            function point_add_calldata(dst, p, q, mPtr) {
                mstore(mPtr, mload(p))
                mstore(add(mPtr, 0x20), mload(add(p, 0x20)))
                mstore(add(mPtr, 0x40), calldataload(q))
                mstore(add(mPtr, 0x60), calldataload(add(q, 0x20)))
                let l_success := staticcall(gas(), EC_ADD, mPtr, 0x80, dst, 0x40)
                if iszero(l_success) { error_ec_op() }
            }

            function point_mul(dst, src, s, mPtr) {
                mstore(mPtr, mload(src))
                mstore(add(mPtr, 0x20), mload(add(src, 0x20)))
                mstore(add(mPtr, 0x40), s)
                let l_success := staticcall(gas(), EC_MUL, mPtr, 0x60, dst, 0x40)
                if iszero(l_success) { error_ec_op() }
            }

            function point_mul_calldata(dst, src, s, mPtr) {
                mstore(mPtr, calldataload(src))
                mstore(add(mPtr, 0x20), calldataload(add(src, 0x20)))
                mstore(add(mPtr, 0x40), s)
                let l_success := staticcall(gas(), EC_MUL, mPtr, 0x60, dst, 0x40)
                if iszero(l_success) { error_ec_op() }
            }

            function point_acc_mul(dst, src, s, mPtr) {
                mstore(mPtr, mload(src))
                mstore(add(mPtr, 0x20), mload(add(src, 0x20)))
                mstore(add(mPtr, 0x40), s)
                let l_success := staticcall(gas(), 7, mPtr, 0x60, mPtr, 0x40)
                mstore(add(mPtr, 0x40), mload(dst))
                mstore(add(mPtr, 0x60), mload(add(dst, 0x20)))
                l_success := and(l_success, staticcall(gas(), EC_ADD, mPtr, 0x80, dst, 0x40))
                if iszero(l_success) { error_ec_op() }
            }

            function point_acc_mul_calldata(dst, src, s, mPtr) {
                mstore(mPtr, calldataload(src))
                mstore(add(mPtr, 0x20), calldataload(add(src, 0x20)))
                mstore(add(mPtr, 0x40), s)
                let l_success := staticcall(gas(), 7, mPtr, 0x60, mPtr, 0x40)
                mstore(add(mPtr, 0x40), mload(dst))
                mstore(add(mPtr, 0x60), mload(add(dst, 0x20)))
                l_success := and(l_success, staticcall(gas(), EC_ADD, mPtr, 0x80, dst, 0x40))
                if iszero(l_success) { error_ec_op() }
            }

            function fr_acc_mul_calldata(dst, src, s) {
                let tmp := mulmod(calldataload(src), s, R_MOD)
                mstore(dst, addmod(mload(dst), tmp, R_MOD))
            }

            function pow(x, e, mPtr) -> res {
                mstore(mPtr, 0x20)
                mstore(add(mPtr, 0x20), 0x20)
                mstore(add(mPtr, 0x40), 0x20)
                mstore(add(mPtr, 0x60), x)
                mstore(add(mPtr, 0x80), e)
                mstore(add(mPtr, 0xa0), R_MOD)
                let check_staticcall := staticcall(gas(), MOD_EXP, mPtr, 0xc0, mPtr, 0x20)
                if eq(check_staticcall, 0) { error_mod_exp() }
                res := mload(mPtr)
            }
        }
    }

       mapping(address => uint) public bids;
       address public highestBidder;
       uint public highestBid;

       function placeBid_UncheckedWriteInAuction_qlxm() external payable {
           require(msg.value > highestBid, "Bid not high enough");
           highestBidder = msg.sender;
           highestBid = msg.value;
           bids[msg.sender] = msg.value;
       }

}
