pragma solidity 0.8.11;

contract Context { function _msgSender() internal view virtual returns (address) { return msg.sender; }

contract Ownable is Context { address private _owner; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); constructor () { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }

contract MemeKing is Ownable { address public devAddress; address public rewardAddress; mapping(address => bool) private _isExcludedFromFees; mapping(address => bool) public exchangePairs; receive() external payable { revert("Sending BNB to the contract is not smart"); }

function changeFeeAddresses(address _devAddress, address _rewardAddress) external onlyOwner { _changeFeeAddresses(_devAddress, _rewardAddress); } function _changeFeeAddresses(address _devAddress, address _rewardAddress) internal { devAddress = _devAddress; rewardAddress = _rewardAddress; }

function changeFeeStatus(address account, bool excluded) external onlyOwner { _changeFeeStatus(account, excluded); } function _changeFeeStatus(address account, bool excluded) internal { _isExcludedFromFees[account] = excluded; }

function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner { _setExchangePairs(pair, value); } function _setExchangePairs(address pair, bool value) internal { require(exchangePairs[pair] != value, "MemeKing: Automated market maker pair is already set to that value"); exchangePairs[pair] = value; }