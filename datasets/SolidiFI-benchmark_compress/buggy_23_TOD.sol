pragma solidity ^0.5.11;
contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
function bug_txorigin20(address owner_txorigin20) public{
        require(tx.origin == owner_txorigin20);
    }
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
pragma solidity ^0.5.2;
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function balanceOf(address who) external view returns (uint256);
      
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
