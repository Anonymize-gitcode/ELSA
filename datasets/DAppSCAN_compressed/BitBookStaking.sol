pragma solidity ^0.6.0;

contract Context { function _msgSender() internal view virtual returns (address payable) { return msg.sender; }

contract Ownable is Context { address private _owner; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); constructor () internal { address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }

contract ReentrancyGuard { uint256 private constant _NOT_ENTERED = 1; uint256 private constant _ENTERED = 2; uint256 private _status; constructor () internal { _status = _NOT_ENTERED; }

interface IBEP20 { function balanceOf(address account) external view returns (uint256); function transfer(address recipient, uint256 amount) external returns (bool); function allowance(address owner, address spender) external view returns (uint256); function approve(address spender, uint256 amount) external returns (bool); function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); }

interface IBEP20Mintable is IBEP20 { function mint(address to, uint256 amount) external; function transferOwnership(address newOwner) external; }

function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c; } function sub(uint256 a, uint256 b) internal pure returns (uint256) { return sub(a, b, "SafeMath: subtraction overflow"); } function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { require(b <= a, errorMessage); uint256 c = a - b; return c; } function mul(uint256 a, uint256 b) internal pure returns (uint256) { if (a == 0) { return 0; } uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c; } function div(uint256 a, uint256 b) internal pure returns (uint256) { return div(a, b, "SafeMath: division by zero"); } function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { require(b > 0, errorMessage); uint256 c = a / b; return c; } } library SafeBEP20 { using SafeMath for uint256; function safeTransfer(IBEP20 token, address to, uint256 value) internal { _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value)); }

function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal { _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value)); }

function safeApprove(IBEP20 token, address spender, uint256 value) internal { require( (value == 0) || (token.allowance(address(this), spender) == 0), "SafeBEP20: approve from non-zero to non-zero allowance" ); _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value)); }

function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal { uint256 newAllowance = token.allowance(address(this), spender).add(value); _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance)); }

function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal { uint256 newAllowance = token.allowance(address(this), spender).sub( value, "SafeBEP20: decreased allowance below zero" ); _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance)); }

function _callOptionalReturn(IBEP20 token, bytes memory data) private { bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed"); if (returndata.length > 0) { require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed"); }

contract Reserve is Ownable { function safeTransfer( IBEP20 rewardToken, address _to, uint256 _amount ) external onlyOwner { uint256 tokenBal = rewardToken.balanceOf(address(this)); if (_amount > tokenBal) { rewardToken.transfer(_to, tokenBal); }

contract BitBookStaking is Ownable { using SafeMath for uint256; using SafeBEP20 for IBEP20; struct WithdrawFeeInterval { uint256 day; uint256 fee; }

struct UserInfo { uint256 amount; uint256 rewardDebt; uint256 rewardLockedUp; uint256 nextHarvestUntil; uint256 depositTimestamp; }

struct PoolInfo { IBEP20 stakedToken; IBEP20 rewardToken; uint256 stakedAmount; uint256 rewardSupply; uint256 tokenPerBlock; uint256 lastRewardBlock; uint256 accTokenPerShare; uint16 depositFeeBP; uint256 minDeposit; uint256 harvestInterval; bool lockDeposit; }

function depositRewardToken(uint256 poolId, uint256 amount) external { PoolInfo storage _poolInfo = poolInfo[poolId]; uint256 initialBalance = _poolInfo.rewardToken.balanceOf(address(rewardReserve)); _poolInfo.rewardToken.safeTransferFrom(msg.sender, address(rewardReserve), amount); uint256 finalBalance = _poolInfo.rewardToken.balanceOf(address(rewardReserve)); _poolInfo.rewardSupply += finalBalance.sub(initialBalance); emit RewardTokenDeposited(msg.sender, poolId, amount); }

function payOrLockupPendingToken(uint256 _pid) internal { PoolInfo storage pool = poolInfo[_pid]; UserInfo storage user = userInfo[_pid][msg.sender]; if (user.nextHarvestUntil == 0) { user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval); }