/*@vulnerable_(SWC: 101)_at_lines: 42*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPReferralSystem {
    address public owner;
    mapping(address => bool) public proofSubmitted;
    mapping(address => uint256) public referralRewards;
    uint256 public totalRewards;

    constructor() {
        owner = msg.sender;
    }

    // Function to submit a zero-knowledge proof for referral verification
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        // Mark proof as submitted
        proofSubmitted[msg.sender] = true;
    }

    // Simple mock verification for ZKP
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // This is a mock logic to simulate the verification of a ZKP
        return (proof[0] * proof[1]) == (input[0] * input[1]);
    }

    // Function to claim referral rewards after proof submission
    function claimReferralReward(uint256 amount) public {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(amount > 0, "Reward amount must be greater than zero");

        referralRewards[msg.sender] += amount;
        totalRewards += amount;
    }

    // Function to withdraw referral rewards, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 42*/
    function withdrawReferralReward(uint256 amount) public {
        require(referralRewards[msg.sender] >= amount, "Insufficient reward balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        // Update the state after external call, leaving the contract open to reentrancy attacks
        referralRewards[msg.sender] -= amount;
        totalRewards -= amount;
    }

    // Function to check referral reward balance
    function getReferralRewardBalance(address referrer) public view returns (uint256) {
        return referralRewards[referrer];
    }

    // Allow the contract to receive Ether for referral rewards
    receive() external payable {}
}
