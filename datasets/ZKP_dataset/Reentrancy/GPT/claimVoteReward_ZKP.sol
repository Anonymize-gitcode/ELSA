/*@vulnerable_(SWC: 107)_at_lines: 37*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ZKP verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPVoteReward {
    IVerifier public verifier;
    mapping(address => bool) public hasVoted;  // Tracks if a user has voted
    mapping(address => uint256) public rewards; // Stores the reward amount for each voter
    uint256 public totalRewardPool;  // Total amount in the reward pool

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalRewardPool = 100 ether;  // Initial reward pool is set to 100 ETH
    }

    // Anyone can donate to the reward pool
    function donateToRewardPool() public payable {
        require(msg.value > 0, "Must send some Ether");
        totalRewardPool += msg.value;
    }

    // Admin sets the reward amount for a voter, only those who voted can claim rewards
    function setRewardForVoter(address _voter, uint256 _rewardAmount) public {
        require(_rewardAmount <= totalRewardPool, "Not enough rewards in the pool");
        rewards[_voter] = _rewardAmount;
    }

    // Users can claim vote rewards after ZKP verification
    function claimVoteReward(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(rewards[msg.sender] >= amount, "Insufficient reward balance");
        require(hasVoted[msg.sender], "User has not voted");

        // ZKP verification to ensure user is eligible for rewards
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // External call for reward transfer
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Reward transfer failed");

        // Update the user's reward balance and the total reward pool
        rewards[msg.sender] -= amount;
        totalRewardPool -= amount;
    }

    // Admin marks a user as having voted
    function markAsVoted(address _voter) public {
        hasVoted[_voter] = true;
    }

    // Query the user's reward balance
    function getRewardBalance() public view returns (uint256) {
        return rewards[msg.sender];
    }
}
