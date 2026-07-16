pragma solidity 0.4.22;
contract Ownable {
address payable winner_TOD21;
function play_TOD21(bytes32 guess) public{
 
       if (keccak256(abi.encode(guess)) == keccak256(abi.encode('hello'))) {
            winner_TOD21 = msg.sender;
        }
    }
function getReward_TOD21() payable public{
pragma solidity ^0.5.10;
contract Ownable {
  address payable winner_TOD21;
function play_TOD21(bytes32 guess) public{
 
       if (keccak256(abi.encode(guess)) == keccak256(abi.encode('hello'))) {
            winner_TOD21 = msg.sender;
        }
    }
function getReward_TOD21() payable public{
