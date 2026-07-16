pragma solidity ^0.8.0;

interface IWaultSwapRouter02 { address factory(); address WETH(); }

interface IWETH { function deposit() external payable; function transfer(address to, uint value) external returns (bool); function withdraw(uint) external; }

contract WaultSwapRouter is IWaultSwapRouter02 { using SafeMath for uint; address public immutable override factory; address public immutable override WETH; modifier ensure(uint deadline) { require(deadline >= block.timestamp, 'WaultSwapRouter: EXPIRED'); _; }

function safeTransfer(address token, address to, uint value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED'); }

function safeTransferFrom(address token, address from, address to, uint value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED'); }

function safeTransferETH(address to, uint value) internal { (bool success,) = to.call{value:value}