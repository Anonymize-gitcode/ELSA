interface IWaultSwapFactory { event PairCreated(address indexed token0, address indexed token1, address pair, uint); }

contract WaultSwapFactory is IWaultSwapFactory { bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(WaultSwapPair).creationCode)); address public feeTo; address public feeToSetter; mapping(address => mapping(address => address)) public getPair; address[] public allPairs; event PairCreated(address indexed token0, address indexed token1, address pair, uint); constructor(address _feeToSetter) public { feeToSetter = _feeToSetter; }

function setFeeToSetter(address _feeToSetter) external { require(msg.sender == feeToSetter, 'WaultSwap: FORBIDDEN'); feeToSetter = _feeToSetter; }

interface IWaultSwapCallee { function waultSwapCall(address sender, uint amount0, uint amount1, bytes calldata data) external; }

contract WaultSwapPair { address public factory; address public token0; address public token1; function initialize(address _token0, address _token1) external { require(msg.sender == factory, 'WaultSwap: FORBIDDEN'); token0 = _token0; token1 = _token1; }