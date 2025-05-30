pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
contract Ownable {
    address public owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    mapping(address => uint) public bids;
    address public highestBidder;
    uint public highestBid;
    function placeBid_ReentrancyInAuction_5uap() external payable {
        require(msg.value > highestBid, "Bid not high enough");
        if (highestBidder != address(0)) {
            (bool success, ) = highestBidder.call{value: highestBid}("");
            require(success, "Refund failed");
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        bids[msg.sender] = msg.value;
    }
    
}
contract Claimable is Ownable {
    address public pendingOwner;
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}
abstract contract ILoopringV3 is Claimable {
    event ExchangeStakeDeposited(address exchangeAddr, uint amount);
    event ExchangeStakeWithdrawn(address exchangeAddr, uint amount);
    event ExchangeStakeBurned(address exchangeAddr, uint amount);
    event SettingsUpdated(uint time);
    mapping (address => uint) internal exchangeStake;
    uint public totalStake;
    address public blockVerifierAddress;
    uint public forcedWithdrawalFee;
    uint public tokenRegistrationFeeLRCBase;
    uint public tokenRegistrationFeeLRCDelta;
    uint8 public protocolTakerFeeBips;
    uint8 public protocolMakerFeeBips;
    address payable public protocolFeeVault;
    function lrcAddress() external view virtual returns (address);
    function updateSettings(address payable _protocolFeeVault, address _blockVerifierAddress, uint _forcedWithdrawalFee) external virtual;
    function updateProtocolFeeSettings(uint8 _protocolTakerFeeBips, uint8 _protocolMakerFeeBips) external virtual;
    function getExchangeStake(address exchangeAddr) public virtual view returns (uint stakedLRC);
    function burnExchangeStake(uint amount) external virtual returns (uint burnedLRC);
    function depositExchangeStake(address exchangeAddr, uint amountLRC) external virtual returns (uint stakedLRC);
    function withdrawExchangeStake(address recipient, uint requestedAmount) external virtual returns (uint amountLRC);
    function getProtocolFeeValues() public virtual view returns (uint8 takerFeeBips, uint8 makerFeeBips);
}
interface IDepositContract {
    function isTokenSupported(address token) external view returns (bool);
    function deposit(address from, address token, uint96 amount, bytes calldata extraData) external payable returns (uint96 amountReceived);
    function withdraw(address from, address to, address token, uint amount, bytes calldata extraData) external payable;
    function transfer(address from, address to, address token, uint amount) external payable;
    function isETH(address addr) external view returns (bool);
}
abstract contract IBlockVerifier is Claimable {
    event CircuitRegistered(uint8 indexed blockType, uint16 blockSize, uint8 blockVersion);
    event CircuitDisabled(uint8 indexed blockType, uint16 blockSize, uint8 blockVersion);
    function registerCircuit(uint8 blockType, uint16 blockSize, uint8 blockVersion, uint[18] calldata vk) external virtual;
    function disableCircuit(uint8 blockType, uint16 blockSize, uint8 blockVersion) external virtual;
    function verifyProofs(uint8 blockType, uint16 blockSize, uint8 blockVersion, uint[] calldata publicInputs, uint[] calldata proofs) external virtual view returns (bool);
    function isCircuitRegistered(uint8 blockType, uint16 blockSize, uint8 blockVersion) external virtual view returns (bool);
    function isCircuitEnabled(uint8 blockType, uint16 blockSize, uint8 blockVersion) external virtual view returns (bool);
}
interface IAgent {}
abstract contract IAgentRegistry {
    function isAgent(address owner, address agent) external virtual view returns (bool);
    function isAgent(address[] calldata owners, address agent) external virtual view returns (bool);
    function isUniversalAgent(address agent) public virtual view returns (bool);
}