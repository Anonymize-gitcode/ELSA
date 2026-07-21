pragma solidity ^0.5.11;
contract digitalNotary
{
    
  bool claimed_TOD2 = false;
address payable owner_TOD2;
uint256 reward_TOD2;
function setReward_TOD2() public payable {
        require (!claimed_TOD2);
        require(msg.sender == owner_TOD2);
        owner_TOD2.transfer(reward_TOD2);
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
pragma solidity ^0.5.0;
contract EventMetadata {
  bool claimed_TOD40 = false;
address payable owner_TOD40;
uint256 reward_TOD40;
function setReward_TOD40() public payable {
        require (!claimed_TOD40);
        require(msg.sender == owner_TOD40);
        owner_TOD40.transfer(reward_TOD40);
