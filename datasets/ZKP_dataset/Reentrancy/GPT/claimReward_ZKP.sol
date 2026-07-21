/*@vulnerable_(SWC: 107)_at_lines: 38*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the ZKP verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPRewardPool {
    IVerifier public verifier;
    mapping(address => uint256) public rewards; // Rewards amount for each user
    uint256 public totalPool; // Total pool amount

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalPool = 1000 ether; // Initialize the reward pool
    }

    // Users can deposit funds to the pool through this function
    function depositToPool() public payable {
        totalPool += msg.value;
    }

    // Set the reward amount for a user (for demonstration purposes, actual ZKP proof is generated off-chain)
    function setReward(address _user, uint256 _amount) public {
        require(_amount <= totalPool, "Not enough funds in the pool");
        rewards[_user] = _amount;
    }

    // Function for users to claim their rewards, requires ZKP verification
    function claimReward(uint256 _amount, bytes memory proof, uint256[2] memory input) public {
        require(rewards[msg.sender] >= _amount, "Insufficient reward balance");

        // Step 1: Verify through the ZKP
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // Step 2: External call to transfer the reward to the user
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Reward transfer failed");

        // Step 3: Update the user's reward balance and the total pool balance
        rewards[msg.sender] -= _amount;
        totalPool -= _amount;
    }
}
