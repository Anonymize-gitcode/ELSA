pragma solidity ^0.6.12;

contract Context { function _msgSender() internal view virtual returns (address payable) { return msg.sender; }

contract Ownable is Context { address private _owner; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); constructor () internal { address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }