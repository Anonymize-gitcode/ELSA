pragma solidity ^0.8.4;

contract Context { function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }

contract Ownable is Context { address private _owner; address private _previousOwner; uint256 private _lockTime; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); constructor() { address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }

interface IUniswapV2Router02 { function factory() external pure returns (address); function WETH() external pure returns (address); function swapExactETHForTokensSupportingFeeOnTransferTokens( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external payable; function addLiquidityETH( address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity); }

interface IUniswapV2Factory { function getPair(address tokenA, address tokenB) external view returns (address pair); function createPair(address tokenA, address tokenB) external returns (address pair); }

contract TokenFunctions { uint256 private _maxTxAmount; function _transfer( address from, address to, uint256 amount ) private { require(from != address(0), "ERC20: transfer from the zero address"); require(to != address(0), "ERC20: transfer to the zero address"); require(amount > 0, "Transfer amount must be greater than zero"); if (from != owner() && to != owner()) { require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount."); }

function swapETHForTokens(uint256 amount) private { address[] memory path = new address[](2); path[0] = uniswapV2Router.WETH(); path[1] = address(this); uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}

function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private { _approve(address(this), address(uniswapV2Router), tokenAmount); uniswapV2Router.addLiquidityETH{value: ethAmount}

function _tokenTransfer( address sender, address recipient, uint256 amount, bool takeFee ) private { if (!takeFee) removeAllFee(); if (_isExcluded[sender] && !_isExcluded[recipient]) { _transferFromExcluded(sender, recipient, amount); }

function _transferStandard( address sender, address recipient, uint256 tAmount ) private { ( uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity ) = _getValues(tAmount); _rOwned[sender] = _rOwned[sender].sub(rAmount); _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); _takeLiquidity(tLiquidity); _reflectFee(rFee, tFee); emit Transfer(sender, recipient, tTransferAmount); }

function _transferToExcluded( address sender, address recipient, uint256 tAmount ) private { ( uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity ) = _getValues(tAmount); _rOwned[sender] = _rOwned[sender].sub(rAmount); _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount); _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); _takeLiquidity(tLiquidity); _reflectFee(rFee, tFee); emit Transfer(sender, recipient, tTransferAmount); }

function _transferFromExcluded( address sender, address recipient, uint256 tAmount ) private { ( uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity ) = _getValues(tAmount); _tOwned[sender] = _tOwned[sender].sub(tAmount); _rOwned[sender] = _rOwned[sender].sub(rAmount); _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); _takeLiquidity(tLiquidity); _reflectFee(rFee, tFee); emit Transfer(sender, recipient, tTransferAmount); }

function _reflectFee(uint256 rFee, uint256 tFee) private { _rTotal = _rTotal.sub(rFee); _tFeeTotal = _tFeeTotal.add(tFee); }

function calculateTaxFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_taxFee).div(10**2); } function calculateLiquidityFee(uint256 _amount) private view returns (uint256) { return _amount.mul(_liquidityFee).div(10**2); } function removeAllFee() private { if (_taxFee == 0 && _liquidityFee == 0) return; _previousTaxFee = _taxFee; _previousLiquidityFee = _liquidityFee; _taxFee = 0; _liquidityFee = 0; }

function restoreAllFee() private { _taxFee = _previousTaxFee; _liquidityFee = _previousLiquidityFee; }

function changeRouterVersion(address _router) public onlyOwner returns (address _pair) { IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router); _pair = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH()); if (_pair == address(0)) { _pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH()); } uniswapV2Pair = _pair; uniswapV2Router = _uniswapV2Router; } receive() external payable {}

struct AddressFee { bool enable; uint256 _taxFee; uint256 _liquidityFee; uint256 _buyTaxFee; uint256 _buyLiquidityFee; uint256 _sellTaxFee; uint256 _sellLiquidityFee; }

struct SellHistories { uint256 time; uint256 bnbAmount; }