// Original Contract File: 0x0319a976c8dea5d31d1cf36eaffd8bec14957179.sol
// Injected vulnerability: Code With No Effects(line 29-39), Typographical Error(line 29-46)
pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;
struct UserInfo {
uint256 amount;
uint256 rewardDebt;
}
struct PoolInfo {
address lpToken;
uint256 allocPoint;
uint256 lastRewardBlock;
uint256 accSushiPerShare;
}
interface ProtocolAdapter {
function adapterType() external pure returns (string memory);
function tokenType() external pure returns (string memory);
function getBalance(address token, address account) external view returns (uint256);
}
interface MasterChef {
function poolLength() external view returns (uint256);
function poolInfo(uint256) external view returns (PoolInfo memory);
function userInfo(uint256, address) external view returns (UserInfo memory);
function pendingSushi(uint256, address) external view returns (uint256);
}
contract SushiStakingAdapter is ProtocolAdapter {
string public constant override adapterType = "Asset";
string public constant override tokenType = "ERC20";
address internal constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
address internal constant MASTER_CHEF = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;


    uint public balnce; // SWC-129: Typo (should be balance)

    function deposit() external payable {
        balnce += msg.value;
    }

    function doNothing() external pure {
        // SWC-135: Code with no effects
    }

    function redundantCode() external pure returns (uint) {
        uint x = 5;
        x; // SWC-135: statement with no effect
        return x;
    }

function getBalance(address token, address account) external view override returns (uint256) {
uint256 length = MasterChef(MASTER_CHEF).poolLength();
if (token == SUSHI) {
uint256 totalRewards = 0;
for(uint256 i = 0; i < length; i++) {
totalRewards += MasterChef(MASTER_CHEF).pendingSushi(i, account);
}
return totalRewards;
} else {
for(uint256 i = 0; i < length; i++) {
UserInfo memory user = MasterChef(MASTER_CHEF).userInfo(i, account);
PoolInfo memory pool = MasterChef(MASTER_CHEF).poolInfo(i);
if (pool.lpToken == token) {
return user.amount;
}
}
return 0;
}
}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
require(b <= a, "SafeMath: subtraction overflow");
uint256 c = a - b;
return c;
}
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
require(c / a == b, "SafeMath: multiplication overflow");
return c;
}
}