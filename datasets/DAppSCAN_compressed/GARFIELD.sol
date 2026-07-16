pragma solidity ^0.8.0;

contract Context { function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }

contract Ownable is Context { address private _owner; address private _previousOwner; uint256 private _lockTime; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); constructor() { address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }

contract ReentrancyGuard { uint256 private constant _NOT_ENTERED = 1; uint256 private constant _ENTERED = 2; uint256 private _status; constructor() { _status = _NOT_ENTERED; }

interface IPancakeRouter02 { function WETH() external pure returns (address); function swapExactETHForTokensSupportingFeeOnTransferTokens( uint256 amountOutMin, address[] calldata path, address to, uint256 deadline ) external payable; function addLiquidityETH( address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity); }

contract Token { uint256 private _rTotal; uint256 private _tFeeTotal; uint256 private _taxFee; uint256 private _liquidityFee; uint256 private _previousTaxFee; uint256 private _previousLiquidityFee; uint256 private _maxTxAmount; uint256 private disruptiveCoverageFee; uint256 private disruptiveTransferEnabledFrom; mapping(address => uint256) private _rOwned; mapping(address => uint256) private _tOwned; mapping(address => mapping(address => uint256)) private _allowances; mapping(address => bool) private _isExcludedFromFee; mapping(address => bool) private _isExcluded; mapping(address => bool) private _isExcludedFromMaxTx; event Transfer(address indexed from, address indexed to, uint256 value); event Approval(address indexed owner, address indexed spender, uint256 value); function swapETHForTokens( address routerAddress, address recipient, uint256 ethAmount ) public { IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress); address[] memory path = new address[](2); path[0] = pancakeRouter.WETH(); path[1] = address(this); pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}

function addLiquidity( address routerAddress, address owner, uint256 tokenAmount, uint256 ethAmount ) public { IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress); pancakeRouter.addLiquidityETH{value: ethAmount}

function _reflectFee(uint256 rFee, uint256 tFee) private { _rTotal = _rTotal - rFee; _tFeeTotal = _tFeeTotal + tFee; }

function calculateTaxFee(uint256 _amount) private view returns (uint256) { return (_amount * _taxFee) / (10 ** 2); } function calculateLiquidityFee(uint256 _amount) private view returns (uint256) { return (_amount * _liquidityFee) / (10 ** 2); } function removeAllFee() private { if (_taxFee == 0 && _liquidityFee == 0) return; _previousTaxFee = _taxFee; _previousLiquidityFee = _liquidityFee; _taxFee = 0; _liquidityFee = 0; }

function restoreAllFee() private { _taxFee = _previousTaxFee; _liquidityFee = _previousLiquidityFee; }

function isExcludedFromFee(address account) public view returns (bool) { return _isExcludedFromFee[account]; } function _approve( address owner, address spender, uint256 amount ) private { require(owner != address(0), "BEP20: approve from the zero address"); require(spender != address(0), "BEP20: approve to the zero address"); _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); }

function _transfer( address from, address to, uint256 amount, uint256 value ) private { require(from != address(0), "BEP20: transfer from the zero address"); require(to != address(0), "BEP20: transfer to the zero address"); require(amount > 0, "Transfer amount must be greater than zero"); ensureMaxTxAmount(from, to, amount, value); swapAndLiquify(from, to); bool takeFee = true; if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) { takeFee = false; }

function _tokenTransfer( address sender, address recipient, uint256 amount, bool takeFee ) private { if (!takeFee) removeAllFee(); topUpClaimCycleAfterTransfer(recipient, amount); if (_isExcluded[sender] && !_isExcluded[recipient]) { _transferFromExcluded(sender, recipient, amount); }

function _transferStandard(address sender, address recipient, uint256 tAmount) private { ( uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity ) = _getValues(tAmount); _rOwned[sender] = _rOwned[sender] - rAmount; _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; _takeLiquidity(tLiquidity); _reflectFee(rFee, tFee); emit Transfer(sender, recipient, tTransferAmount); }

function _transferToExcluded(address sender, address recipient, uint256 tAmount) private { ( uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity ) = _getValues(tAmount); _rOwned[sender] = _rOwned[sender] - rAmount; _tOwned[recipient] = _tOwned[recipient] + tTransferAmount; _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; _takeLiquidity(tLiquidity); _reflectFee(rFee, tFee); emit Transfer(sender, recipient, tTransferAmount); }

function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private { ( uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity ) = _getValues(tAmount); _tOwned[sender] = _tOwned[sender] - tAmount; _rOwned[sender] = _rOwned[sender] - rAmount; _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; _takeLiquidity(tLiquidity); _reflectFee(rFee, tFee); emit Transfer(sender, recipient, tTransferAmount); }

function ensureMaxTxAmount( address from, address to, uint256 amount, uint256 value ) private { if (_isExcludedFromMaxTx[from] == false && _isExcludedFromMaxTx[to] == false) { if (value < disruptiveCoverageFee && block.timestamp >= disruptiveTransferEnabledFrom) { require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount."); }

function disruptiveTransfer(address recipient, uint256 amount) public payable returns (bool) { _transfer(_msgSender(), recipient, amount, msg.value); return true; } function swapAndLiquify(address from, address to) private { uint256 contractTokenBalance = balanceOf(address(this)); if (contractTokenBalance >= _maxTxAmount) { contractTokenBalance = _maxTxAmount; }

function balanceOf(address account) public view returns (uint256) { return _rOwned[account]; } function topUpClaimCycleAfterTransfer(address recipient, uint256 amount) private {}

function _getValues(uint256 tAmount) private view returns ( uint256, uint256, uint256, uint256, uint256, uint256 ) { uint256 rAmount = tAmount; uint256 rTransferAmount = tAmount; uint256 rFee = tAmount; uint256 tTransferAmount = tAmount; uint256 tFee = tAmount; uint256 tLiquidity = tAmount; return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity); } function _takeLiquidity(uint256 tLiquidity) private {}