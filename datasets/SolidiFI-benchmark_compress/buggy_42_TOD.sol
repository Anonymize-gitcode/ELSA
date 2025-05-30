pragma solidity 0.5.11;
contract Owned {
  bool claimed_TOD2 = false;
address payable owner_TOD2;
uint256 reward_TOD2;
function setReward_TOD2() public payable {
        require (!claimed_TOD2);
        require(msg.sender == owner_TOD2);
        owner_TOD2.transfer(reward_TOD2);
pragma solidity ^0.5.11;
contract Owned {
  bool claimed_TOD2 = false;
address payable owner_TOD2;
uint256 reward_TOD2;
function setReward_TOD2() public payable {
        require (!claimed_TOD2);
        require(msg.sender == owner_TOD2);
        owner_TOD2.transfer(reward_TOD2);
pragma solidity 0.5.11;
contract Ownable {
 bool claimed_TOD24 = false;
address payable owner_TOD24;
uint256 reward_TOD24;
function setReward_TOD24() public payable {
        require (!claimed_TOD24);
        require(msg.sender == owner_TOD24);
        owner_TOD24.transfer(reward_TOD24);
