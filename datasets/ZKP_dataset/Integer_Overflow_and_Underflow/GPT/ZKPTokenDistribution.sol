/*@vulnerable_(SWC: 101)_at_lines: 35*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPTokenDistribution {
    address public owner;
    mapping(address => uint256) public tokenBalances;
    mapping(address => bool) public hasClaimedTokens;

    uint256 public totalTokens;

    constructor(uint256 _totalTokens) {
        owner = msg.sender;
        totalTokens = _totalTokens;
    }

    // Function to claim tokens using a zero-knowledge proof
    function claimTokens(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!hasClaimedTokens[msg.sender], "Tokens already claimed");

        uint256 tokensToClaim = calculateTokens(input);
        require(tokensToClaim <= totalTokens, "Not enough tokens available");

        // Update state before distribution
        tokenBalances[msg.sender] += tokensToClaim;
        totalTokens -= tokensToClaim;
        hasClaimedTokens[msg.sender] = true;
    }

    // Simple mock verification function for ZKP
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Simulated ZKP verification logic for demonstration purposes
        return (proof[0] + proof[1]) == (input[0] + input[1]);
    }

    // Calculate the number of tokens to be claimed based on input
    function calculateTokens(uint256[2] memory input) internal pure returns (uint256) {
        // Simple calculation logic for demonstration purposes
        return input[0] * input[1];
    }

    // Function to withdraw tokens, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 35*/
    function withdrawTokens(uint256 amount) public {
        require(hasClaimedTokens[msg.sender], "No tokens to withdraw");
        require(amount <= tokenBalances[msg.sender], "Insufficient token balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Token withdrawal failed");

        // Update state after external call, making it vulnerable to reentrancy attacks
        tokenBalances[msg.sender] -= amount;
        hasClaimedTokens[msg.sender] = false;
    }

    // Function to deposit Ether into the contract for token value
    receive() external payable {}
}
