pragma solidity 0.5.11;
contract Ownable {
 function bug_txorigin24(  address owner_txorigin24) public{
        require(tx.origin == owner_txorigin24);
    }
  address payable public owner;
 function transferTo_txorigin27(address to, uint amount,address owner_txorigin27) public {
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
