/*@vulnerable_(SWC: 101)_at_lines: 43*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPGrantDistribution {
    address public owner;
    mapping(address => uint256) public grants;
    mapping(address => bool) public proofSubmitted;
    uint256 public totalGrants;

    constructor() {
        owner = msg.sender;
        totalGrants = 1000 ether;  // Initial grant pool
    }

    // Function to submit a zero-knowledge proof for grant eligibility
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        // Mark proof as submitted
        proofSubmitted[msg.sender] = true;
    }

    // Simple mock verification function for ZKP
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Simulated ZKP verification logic (mocked)
        return (proof[0] * proof[1]) == (input[0] * input[1]);
    }

    // Function to allocate grants after proof submission
    function allocateGrant(uint256 amount) public {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(amount > 0, "Grant amount must be greater than zero");
        require(totalGrants >= amount, "Insufficient grant funds");

        grants[msg.sender] += amount;
        totalGrants -= amount;
    }

    // Function to withdraw granted funds, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 43*/
    function withdrawGrant(uint256 amount) public {
        require(grants[msg.sender] >= amount, "Insufficient grant balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Grant withdrawal failed");

        // Update state after external call, leaving contract open to reentrancy attacks
        grants[msg.sender] -= amount;
    }

    // Function to check the grant balance of a specific address
    function getGrantBalance(address grantee) public view returns (uint256) {
        return grants[grantee];
    }

    // Allow the contract to receive Ether to fund the grants
    receive() external payable {}
}
