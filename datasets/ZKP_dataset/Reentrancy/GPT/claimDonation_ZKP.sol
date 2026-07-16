/*@vulnerable_(SWC: 107)_at_lines: 31*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ZKP verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPDonation {
    IVerifier public verifier;
    mapping(address => uint256) public donations; // Donation amount per user
    uint256 public totalDonations; // Total donation amount

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalDonations = 0; // Initialize the donation amount
    }

    // Allows users to deposit funds as donations
    function donate() public payable {
        require(msg.value > 0, "Donation must be greater than 0");
        donations[msg.sender] += msg.value;
        totalDonations += msg.value;
    }

    // Function for users to claim donations through ZKP verification
    function claimDonation(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(donations[msg.sender] >= amount, "Insufficient donation balance");

        // Verify user's eligibility through zero-knowledge proof
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // External call without updating balance first
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Update user's donation balance and total donations after external call
        donations[msg.sender] -= amount;
        totalDonations -= amount;
    }

    // Query the donation balance of a user
    function getDonationBalance() public view returns (uint256) {
        return donations[msg.sender];
    }
}
