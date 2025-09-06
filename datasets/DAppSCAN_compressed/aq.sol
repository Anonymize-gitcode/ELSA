pragma solidity ^0.6.0;

contract Context { function _msgSender() internal virtual view returns (address payable) { return msg.sender; }

function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c; } } contract Ownable is Context { address private _owner; event OwnershipTransferred( address indexed previousOwner, address indexed newOwner ); constructor() internal { address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }

contract aqarchain is Ownable { using SafeMath for uint256; struct seedUserInfo { string firstname; string lastname; string country; uint256 amount; uint256 phase; string aqarid; string modeofpayment; }

struct privateUserInfo { string firstname; string lastname; string country; uint256 amount; uint256 phase; string aqarid; string modeofpayment; }

struct publicUserInfo { string firstname; string lastname; string country; uint256 amount; uint256 phase; string aqarid; string modeofpayment; }

function claim() external { require(claimbool == true, "claiming amount should be true"); claimamount = usermappublic[msg.sender].amount.add(usermapseed[msg.sender].amount).add(usermapprivate[msg.sender].amount); //token.transfer(msg.sender,claimamount); usermappublic[msg.sender].amount=0; usermapprivate[msg.sender].amount=0; usermapseed[msg.sender].amount=0; claimamount=0; }