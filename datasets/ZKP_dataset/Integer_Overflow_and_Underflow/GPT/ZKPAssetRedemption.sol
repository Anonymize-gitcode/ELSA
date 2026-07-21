/*@vulnerable_(SWC: 101)_at_lines: 43*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAssetRedemption {
    address public owner;
    mapping(address => uint256) public assetBalances;
    mapping(address => bool) public proofSubmitted;
    uint256 public totalAssets;

    constructor() {
        owner = msg.sender;
        totalAssets = 1000 ether; // Initial asset pool
    }

    // Function to submit a zero-knowledge proof for asset redemption eligibility
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        // Mark proof as submitted
        proofSubmitted[msg.sender] = true;
    }

    // Simple mock verification function for ZKP
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Simulated ZKP verification logic (mocked for demonstration)
        return (proof[0] ^ proof[1]) == (input[0] ^ input[1]);
    }

    // Function to allocate assets after proof submission
    function allocateAssets(uint256 amount) public {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(amount > 0, "Amount must be greater than zero");
        require(totalAssets >= amount, "Not enough assets available");

        assetBalances[msg.sender] += amount;
        totalAssets -= amount;
    }

    // Function to withdraw assets, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 43*/
    function withdrawAssets(uint256 amount) public {
        require(assetBalances[msg.sender] >= amount, "Insufficient asset balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Asset withdrawal failed");

        // Update state after external call, opening up reentrancy vulnerability
        assetBalances[msg.sender] -= amount;
    }

    // Function to check the asset balance of a user
    function getAssetBalance(address user) public view returns (uint256) {
        return assetBalances[user];
    }

    // Allow the contract to receive Ether to fund the asset pool
    receive() external payable {}
}
