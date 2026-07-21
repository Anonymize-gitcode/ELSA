/*@vulnerable_(SWC: 101)_at_lines: 38*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPSimpleVoting {
    address public owner;
    mapping(address => bool) public hasVoted;
    mapping(bytes32 => uint256) public candidates;
    uint256 public totalVotes;

    constructor() {
        owner = msg.sender;
    }

    // Function to submit a vote using a zero-knowledge proof
    function submitVote(bytes32 candidate, uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid proof");
        require(!hasVoted[msg.sender], "You have already voted");

        // Register the vote
        candidates[candidate] += 1;
        hasVoted[msg.sender] = true;
        totalVotes += 1;
    }

    // Simple mock verification function for ZKP
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // This is a simplified verification logic for demonstration purposes.
        return (proof[0] ^ proof[1]) == (input[0] ^ input[1]);
    }

    // Function to withdraw rewards after voting, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 38*/
    function withdrawReward(uint256 amount) public {
        require(hasVoted[msg.sender], "You must vote before withdrawing rewards");
        require(amount <= address(this).balance, "Insufficient balance in contract");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Update the state after external call, making it susceptible to reentrancy attacks
        hasVoted[msg.sender] = false;
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
