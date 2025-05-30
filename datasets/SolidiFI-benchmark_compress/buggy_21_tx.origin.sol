    }
    function transfer(address _to, uint256 _value) public returns (bool);
function bug_txorigin12(address owner_txorigin12) public{
        require(tx.origin == owner_txorigin12);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
pragma solidity ^0.5.11;
contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
function bug_txorigin20(address owner_txorigin20) public{
        require(tx.origin == owner_txorigin20);
    }
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
pragma solidity ^0.5.11;
contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
function bug_intou20(uint8 p_intou20) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou20;   // overflow bug
}
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
        _recipient.transfer(address(this).balance);
    }
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
function bug_txorigin12(address owner_txorigin12) public{
        require(tx.origin == owner_txorigin12);
