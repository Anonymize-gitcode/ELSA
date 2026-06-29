/*@vulnerable_(SWC: 101)_at_lines: 38*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPDonation {
    address public owner;
    uint256 public totalDonations;
    mapping(address => uint256) public donations;
    mapping(address => bool) public proofSubmitted;

    constructor() {
        owner = msg.sender;
    }

    // Function to submit a zero-knowledge proof for donation verification
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        proofSubmitted[msg.sender] = true;
    }

    // Simple mock ZKP verification function
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Simulate ZKP verification logic (mocked)
        return (proof[0] + proof[1]) == (input[0] + input[1]);
    }

    // Function to donate Ether to the contract
    function donate() public payable {
        require(proofSubmitted[msg.sender], "You must submit a valid proof to donate");
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;
    }

    // Function to withdraw donations, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 38*/
    function withdrawDonations(uint256 amount) public {
        require(donations[msg.sender] >= amount, "Insufficient donation balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        // State update after external call, vulnerable to reentrancy attacks
        donations[msg.sender] -= amount;
        totalDonations -= amount;
    }

    // Function to view the total donations of a specific address
    function getDonationBalance(address donor) public view returns (uint256) {
        return donations[donor];
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
