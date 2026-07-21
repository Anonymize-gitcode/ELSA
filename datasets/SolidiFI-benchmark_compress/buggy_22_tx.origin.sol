pragma solidity ^0.5.11;
contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
function bug_txorigin20(address owner_txorigin20) public{
        require(tx.origin == owner_txorigin20);
    }
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
pragma solidity 0.5.1;
contract owned {
  function bug_intou24(uint8 p_intou24) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou24;   // overflow bug
}
  address public owner;
    constructor() public {
        owner = msg.sender;
    }
function bug_intou11() public{
pragma solidity 0.5.1;
contract owned {
  function bug_txorigin24(  address owner_txorigin24) public{
        require(tx.origin == owner_txorigin24);
    }
  address public owner;
    constructor() public {
        owner = msg.sender;
    }
function transferTo_txorigin11(address to, uint amount,address owner_txorigin11) public {
  require(tx.origin == owner_txorigin11);
  to.call.value(amount);
}
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
function sendto_txorigin1(address payable receiver, uint amount,address owner_txorigin1) public {
  require(tx.origin == owner_txorigin31);
  to.call.value(amount);
}
  event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }
function sendto_txorigin1(address payable receiver, uint amount,address owner_txorigin1) public {
