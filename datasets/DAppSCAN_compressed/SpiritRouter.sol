pragma solidity ^0.8.0;

interface IPancakeRouter02 { function factory() external view returns (address); function WETH() external view returns (address); }

contract SpiritRouter is IPancakeRouter02 { using SafeMath for uint; address public immutable override factory; address public immutable override WETH; modifier ensure(uint deadline) { require(deadline >= block.timestamp, 'SpiritRouter: EXPIRED'); _; }

interface IWETH { function deposit() external payable; function transfer(address to, uint value) external returns (bool); function withdraw(uint) external; }

function add(uint a, uint b) internal pure returns (uint) { uint c = a + b; require(c >= a, "SafeMath: addition overflow"); return c; } function sub(uint a, uint b) internal pure returns (uint) { return sub(a, b, "SafeMath: subtraction overflow"); } function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) { require(b <= a, errorMessage); uint c = a - b; return c; } function mul(uint a, uint b) internal pure returns (uint) { if (a == 0) { return 0; } uint c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c; } function div(uint a, uint b) internal pure returns (uint) { return div(a, b, "SafeMath: division by zero"); } function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) { require(b > 0, errorMessage); uint c = a / b; return c; } function mod(uint a, uint b) internal pure returns (uint) { return mod(a, b, "SafeMath: modulo by zero"); } function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) { require(b > 0, errorMessage); return a % b; } } library TransferHelper { function safeTransfer(address token, address to, uint value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED'); }

function safeTransferFrom(address token, address from, address to, uint value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED'); }

function safeTransferETH(address to, uint value) internal { (bool success,) = to.call{value:value}