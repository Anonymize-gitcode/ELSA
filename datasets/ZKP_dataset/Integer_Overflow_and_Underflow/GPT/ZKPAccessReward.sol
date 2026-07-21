/*@vulnerable_(SWC: 101)_at_lines: 37*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAccessReward {
    address public owner;
    uint256 public rewardPool;
    mapping(address => bool) public accessGranted;
    mapping(address => uint256) public rewardsClaimed;

    constructor() payable {
        owner = msg.sender;
        rewardPool = msg.value;
    }

    // Function to grant access using a zero-knowledge proof
    function requestAccess(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!accessGranted[msg.sender], "Access already granted");

        // Grant access
        accessGranted[msg.sender] = true;
    }

    // Simple mock verification function for ZKP
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // This is a mock ZKP verification logic for demonstration purposes
        return (proof[0] * proof[1]) == (input[0] * input[1]);
    }

    // Function to claim rewards after gaining access, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 37*/
    function claimReward(uint256 amount) public {
        require(accessGranted[msg.sender], "Access not granted");
        require(amount <= rewardPool, "Insufficient reward pool");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Reward claim failed");

        // Update state after external call, making it vulnerable to reentrancy attacks
        rewardsClaimed[msg.sender] += amount;
        rewardPool -= amount;
    }

    // Function to deposit Ether into the reward pool
    function depositRewards() public payable {
        rewardPool += msg.value;
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
