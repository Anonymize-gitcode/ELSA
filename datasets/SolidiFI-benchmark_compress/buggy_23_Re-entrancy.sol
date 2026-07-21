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
function bug_unchk_send17() payable public{
      msg.sender.transfer(1 ether);}
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
pragma solidity ^0.5.11;
contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
bool claimed_TOD20 = false;
address payable owner_TOD20;
uint256 reward_TOD20;
function setReward_TOD20() public payable {
        require (!claimed_TOD20);
    
    function balanceOf(address who) external view returns (uint256);
      
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
pragma solidity ^0.5.2;
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
