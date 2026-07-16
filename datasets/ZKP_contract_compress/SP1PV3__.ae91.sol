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

       mapping(address => uint) public deposits;

       function deposit_UncheckedWriteInEscrow_zewf() external payable {
           deposits[msg.sender] += msg.value;
       }

       function withdraw_UncheckedWriteInEscrow_zewf(uint _amount) external {
           require(deposits[msg.sender] >= _amount, "Insufficient balance");
           deposits[msg.sender] -= _amount;
           (bool success, ) = msg.sender.call{value: _amount}("");
           require(success, "Transfer failed");
       }

}
