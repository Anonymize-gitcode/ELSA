pragma solidity ^0.8.4;

contract Context { function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }

contract Ownable is Context { address private _owner; address private _previousOwner; uint256 private _lockTime; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); constructor() { address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }

interface IUniswapV2Router02 { function factory() external pure returns (address); function WETH() external pure returns (address); function swapExactETHForTokensSupportingFeeOnTransferTokens( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external payable; function addLiquidityETH( address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity); }

interface IUniswapV2Factory { function getPair(address tokenA, address tokenB) external view returns (address pair); function createPair(address tokenA, address tokenB) external returns (address pair); }

contract ERC20 { event Transfer(address indexed from, address indexed to, uint256 value); function _transfer(address from, address to, uint256 amount) internal virtual; }

struct AddressFee { bool enable; uint256 _taxFee; uint256 _liquidityFee; uint256 _buyTaxFee; uint256 _buyLiquidityFee; uint256 _sellTaxFee; uint256 _sellLiquidityFee; }

struct SellHistories { uint256 time; uint256 bnbAmount; }