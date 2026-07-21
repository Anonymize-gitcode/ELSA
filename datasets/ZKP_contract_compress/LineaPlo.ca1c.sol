pragma solidity 0.8.33;

interface IPlonkVerifier {

  struct ChainConfigurationParameter {
    bytes32 value;
    string name;
  }

  event ChainConfigurationSet(bytes32 chainConfigurationHash, ChainConfigurationParameter[] parameters);

  error ChainConfigurationNotProvided();

  function getChainConfiguration() external view returns (bytes32);

  function Verify(bytes calldata _proof, uint256[] calldata _public_inputs) external returns (bool success);

}

library Mimc {

  error DataMissing();

  error DataIsNotMod32();

  uint256 constant FR_FIELD = 8444461749428370424248824938781546531375899335154063827935233455917409239041;

}

contract PlonkVerifierForDataAggregation is IPlonkVerifier {

  uint256 private constant R_MOD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  uint256 private constant R_MOD_MINUS_ONE =
    21888242871839275222246405745257275088548364400416034343698204186575808495616;

  uint256 private constant P_MOD = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  uint256 private constant G2_SRS_0_X_0 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;

  uint256 private constant G2_SRS_0_X_1 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;

  uint256 private constant G2_SRS_0_Y_0 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;

  uint256 private constant G2_SRS_0_Y_1 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;

  uint256 private constant G2_SRS_1_X_0 = 15805639136721018565402881920352193254830339253282065586954346329754995870280;

  uint256 private constant G2_SRS_1_X_1 = 19089565590083334368588890253123139704298730990782503769911324779715431555531;

  uint256 private constant G2_SRS_1_Y_0 = 9779648407879205346559610309258181044130619080926897934572699915909528404984;

  uint256 private constant G2_SRS_1_Y_1 = 6779728121489434657638426458390319301070371227460768374343986326751507916979;

  uint256 private constant G1_SRS_X = 14312776538779914388377568895031746459131577658076416373430523308756343304251;

  uint256 private constant G1_SRS_Y = 11763105256161367503191792604679297387056316997144156930871823008787082098465;

  uint256 private constant VK_NB_PUBLIC_INPUTS = 1;

  uint256 private constant VK_DOMAIN_SIZE = 16;

  uint256 private constant VK_INV_DOMAIN_SIZE =
    20520227692349320520856005386178695395514091625390032197217066424914820464641;

  uint256 private constant VK_OMEGA = 14940766826517323942636479241147756311199852622225275649687664389641784935947;

  uint256 private constant VK_QL_COM_X = 3767637989833674092151354229632559107224950590673664856842061399469467338879;

  uint256 private constant VK_QL_COM_Y = 18545409996679466114224178746162553880737296402729089689774308937082946761979;

  uint256 private constant VK_QR_COM_X = 17695083696096292739863947479309285121876115122027754616771640943170154880365;

  uint256 private constant VK_QR_COM_Y = 18848792137060584485073656009873304591711473348092340750543309609927380557217;

  uint256 private constant VK_QM_COM_X = 19254633954172656160276364845360694495419838651579149060453111119493783709110;

  uint256 private constant VK_QM_COM_Y = 3754968212794555693992404588204431907755436950393461523526335570307736307542;

  uint256 private constant VK_QO_COM_X = 5406300062356418594067419088824593563585032084905591722441567109355735073610;

  uint256 private constant VK_QO_COM_Y = 10782414695040549646706468913781794882209258381887890407509684555513355143197;

  uint256 private constant VK_QK_COM_X = 309591480144351325314158474719361148480191595146291661238142838254651436989;

  uint256 private constant VK_QK_COM_Y = 12063173869829536468830946547606069911666129778788708678515573607390482939756;

  uint256 private constant VK_S1_COM_X = 12287072751694848944507699577006619791724925439540371477056092891137357229312;

  uint256 private constant VK_S1_COM_Y = 2469356406782415219782253630635766217009619642857495098799013714324696399305;

  uint256 private constant VK_S2_COM_X = 17261757720471042341269061128759148572672168808566386603388432325173708264418;

  uint256 private constant VK_S2_COM_Y = 20976565876611279190744172824963243461988367679364518747954008723085439460611;

  uint256 private constant VK_S3_COM_X = 18758025488249277181117376239193628449359868741625564388668468130204669284937;

  uint256 private constant VK_S3_COM_Y = 15566903578741238761792344329051427316196307361197991677131114502821508927172;

  uint256 private constant VK_COSET_SHIFT = 5;

  uint256 private constant VK_QCP_0_X = 4559262075452024065272338216146989708834054079507534161096300708463935456394;

  uint256 private constant VK_QCP_0_Y = 1898950104727986554890445533779776634695458253078091580309593009754027486622;

  uint256 private constant VK_INDEX_COMMIT_API_0 = 5;

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

  uint256 private constant ERROR_STRING_ID = 0x08c379a000000000000000000000000000000000000000000000000000000000;

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

  bytes32 private immutable CHAIN_CONFIGURATION;

  constructor(ChainConfigurationParameter[] memory _chainConfiguration) {
    if (_chainConfiguration.length == 0) {
      revert ChainConfigurationNotProvided();
    }

    bytes32 chainConfigurationHash = _computeChainConfigurationHash(_chainConfiguration);

    CHAIN_CONFIGURATION = chainConfigurationHash;

    emit ChainConfigurationSet(chainConfigurationHash, _chainConfiguration);
  }

  function _computeChainConfigurationHash(
    ChainConfigurationParameter[] memory _chainConfiguration
  ) internal pure returns (bytes32 chainConfigurationHash) {
    bytes memory mimcPayload;
    bytes32 value;
    for (uint256 i; i < _chainConfiguration.length; i++) {
      value = _chainConfiguration[i].value;

      bool firstBitIsZero;
      assembly {
        firstBitIsZero := iszero(shr(255, value))
      }

      if (firstBitIsZero) {
        mimcPayload = bytes.concat(mimcPayload, value);
      } else {
        bytes32 most;
        bytes32 least;

        assembly {
          most := shr(128, value)
          least := and(value, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        mimcPayload = bytes.concat(mimcPayload, most, least);
      }
    }

    chainConfigurationHash = Mimc.hash(mimcPayload);
  }

  function getChainConfiguration() external view returns (bytes32) {
    return CHAIN_CONFIGURATION;
  }

       mapping(address => uint) public deposits;

       function deposit_UncheckedWriteInEscrow_jdsn() external payable {
           deposits[msg.sender] += msg.value;
       }

       function withdraw_UncheckedWriteInEscrow_jdsn(uint _amount) external {
           require(deposits[msg.sender] >= _amount, "Insufficient balance");
           deposits[msg.sender] -= _amount;
           (bool success, ) = msg.sender.call{value: _amount}("");
           require(success, "Transfer failed");
       }

}
