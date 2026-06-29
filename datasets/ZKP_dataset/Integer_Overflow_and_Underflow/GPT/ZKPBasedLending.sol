/*@vulnerable_(SWC: 101)_at_lines: 39*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPBasedLending {
    address public owner;
    mapping(address => uint256) public loanBalances;
    mapping(address => bool) public proofSubmitted;

    uint256 public totalLoans;

    constructor() {
        owner = msg.sender;
    }

    // Function to submit a zero-knowledge proof for loan eligibility
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        // Mark the proof as submitted
        proofSubmitted[msg.sender] = true;
    }

    // Simple mock ZKP verification function
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Simulated ZKP verification logic (mocked for demonstration)
        return (proof[0] * proof[1]) == (input[0] * input[1]);
    }

    // Function to take out a loan after submitting a valid proof
    function takeLoan(uint256 amount) public {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(amount > 0, "Loan amount must be greater than zero");

        loanBalances[msg.sender] += amount;
        totalLoans += amount;
    }

    // Function to repay the loan, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 39*/
    function repayLoan(uint256 amount) public {
        require(loanBalances[msg.sender] >= amount, "Repay amount exceeds loan balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Repayment failed");

        // Update state after external call, vulnerable to reentrancy attacks
        loanBalances[msg.sender] -= amount;
        totalLoans -= amount;
    }

    // Function to check the loan balance of a specific address
    function getLoanBalance(address borrower) public view returns (uint256) {
        return loanBalances[borrower];
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
