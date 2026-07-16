/*@vulnerable_(SWC: 107)_at_lines: 26*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ZKP verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPLoan {
    IVerifier public verifier;
    mapping(address => uint256) public loanBalances; // Loan balance for each user
    uint256 public totalLoanPool; // Funds available for loans in the contract

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalLoanPool = 100 ether; // Initialize loan pool with 100 ETH
    }

    // Deposit function to allow users to add funds to the loan pool
    function depositToLoanPool() public payable {
        require(msg.value > 0, "Must send some Ether");
        totalLoanPool += msg.value;
    }

    // Loan function, using ZKP to verify the user's eligibility for a loan
    function takeLoan(uint256 loanAmount, bytes memory proof, uint256[2] memory input) public {
        require(totalLoanPool >= loanAmount, "Not enough funds in loan pool");

        // Verify the user's loan eligibility using Zero-Knowledge Proof
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        (bool success, ) = msg.sender.call{value: loanAmount}("");
        require(success, "Loan transfer failed");

        // Update loan balance and total loan pool balance
        loanBalances[msg.sender] += loanAmount;
        totalLoanPool -= loanAmount;
    }

    // Repayment function to allow users to reduce their loan balance
    function repayLoan() public payable {
        require(loanBalances[msg.sender] >= msg.value, "Repay amount exceeds loan balance");
        loanBalances[msg.sender] -= msg.value;
        totalLoanPool += msg.value;
    }

    // View function to check the user's loan balance
    function getLoanBalance() public view returns (uint256) {
        return loanBalances[msg.sender];
    }
}
