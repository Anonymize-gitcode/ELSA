/*@vulnerable_(SWC: 101)_at_lines: 44*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPStakingRewards {
    address public owner;
    mapping(address => uint256) public stakedAmounts;
    mapping(address => uint256) public rewardBalances;
    mapping(address => bool) public proofSubmitted;
    uint256 public totalStaked;
    uint256 public totalRewards;

    constructor() {
        owner = msg.sender;
    }

    // Function to submit a zero-knowledge proof for staking eligibility
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        // Mark proof as submitted
        proofSubmitted[msg.sender] = true;
    }

    // Simple mock ZKP verification function
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // This is a simplified verification logic for the demonstration
        return (proof[0] + proof[1]) == (input[0] + input[1]);
    }

    // Function to stake tokens and earn rewards
    function stakeTokens(uint256 amount) public {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(amount > 0, "Amount must be greater than zero");

        stakedAmounts[msg.sender] += amount;
        totalStaked += amount;
    }

    // Function to claim staking rewards after staking
    function claimRewards(uint256 rewardAmount) public {
        require(stakedAmounts[msg.sender] > 0, "You need to stake tokens first");
        require(rewardAmount > 0, "Reward amount must be greater than zero");

        rewardBalances[msg.sender] += rewardAmount;
        totalRewards += rewardAmount;
    }

    // Function to withdraw rewards, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 44*/
    function withdrawRewards(uint256 rewardAmount) public {
        require(rewardBalances[msg.sender] >= rewardAmount, "Insufficient reward balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        require(success, "Withdrawal failed");

        // Update state after external call, allowing for reentrancy attack
        rewardBalances[msg.sender] -= rewardAmount;
        totalRewards -= rewardAmount;
    }

    // Function to check staked balance
    function getStakedBalance(address staker) public view returns (uint256) {
        return stakedAmounts[staker];
    }

    // Function to check reward balance
    function getRewardBalance(address staker) public view returns (uint256) {
        return rewardBalances[staker];
    }

    // Allow contract to receive Ether for staking rewards
    receive() external payable {}
}
