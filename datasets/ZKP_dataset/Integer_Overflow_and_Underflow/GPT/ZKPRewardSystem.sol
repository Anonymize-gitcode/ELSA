/*@vulnerable_(SWC: 101)_at_lines: 40*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPRewardSystem {
    address public owner;
    mapping(address => uint256) public rewards;
    mapping(address => bool) public proofSubmitted;
    uint256 public totalRewards;

    constructor() {
        owner = msg.sender;
    }

    // Function to submit a zero-knowledge proof for reward eligibility
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        // Mark proof as submitted
        proofSubmitted[msg.sender] = true;
    }

    // Simple mock ZKP verification function
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Simulated ZKP verification logic (mocked)
        return (proof[0] + proof[1]) == (input[0] + input[1]);
    }

    // Function to claim rewards after submitting proof
    function claimReward(uint256 amount) public {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(amount > 0, "Amount must be greater than zero");

        rewards[msg.sender] += amount;
        totalRewards += amount;
    }

    // Function to withdraw rewards, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 40*/
    function withdrawReward(uint256 amount) public {
        require(rewards[msg.sender] >= amount, "Insufficient reward balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        // Update state after external call, allowing for potential reentrancy attack
        rewards[msg.sender] -= amount;
        totalRewards -= amount;
    }

    // Function to check the reward balance of a specific address
    function getRewardBalance(address user) public view returns (uint256) {
        return rewards[user];
    }

    // Allow the contract to receive Ether for rewards
    receive() external payable {}
}
