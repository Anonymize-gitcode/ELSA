/*@vulnerable_(SWC: 101)_at_lines: 41*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPInsurance {
    address public owner;
    uint256 public totalPayouts;
    mapping(address => uint256) public insuranceClaims;
    mapping(address => bool) public proofSubmitted;

    constructor() {
        owner = msg.sender;
    }

    // Function to submit a zero-knowledge proof for insurance claim eligibility
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        // Register the proof
        proofSubmitted[msg.sender] = true;
    }

    // Simple mock ZKP verification function
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Simulate ZKP verification logic (mocked for demonstration)
        return (proof[0] + proof[1]) == (input[0] + input[1]);
    }

    // Function to claim insurance after proof submission
    function claimInsurance(uint256 amount) public {
        require(proofSubmitted[msg.sender], "You must submit a valid proof to claim");
        require(amount > 0, "Claim amount must be greater than zero");

        insuranceClaims[msg.sender] += amount;
        totalPayouts += amount;
    }

    // Function to withdraw insurance claim, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 41*/
    function withdrawClaim(uint256 amount) public {
        require(insuranceClaims[msg.sender] >= amount, "Insufficient claim balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");

        // Update state after external call, leaving it open to reentrancy attacks
        insuranceClaims[msg.sender] -= amount;
        totalPayouts -= amount;
    }

    // Function to check the claim balance of a specific address
    function getClaimBalance(address claimant) public view returns (uint256) {
        return insuranceClaims[claimant];
    }

    // Allow the contract to receive Ether for insurance pool
    receive() external payable {}
}
