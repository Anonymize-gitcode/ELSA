pragma solidity ^0.8.0;
contract ZKPBasedLending {
    address public owner;
    mapping(address => uint256) public loanBalances;
    mapping(address => bool) public proofSubmitted;
    uint256 public totalLoans;
    constructor() {
        owner = msg.sender;
    }
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");
        proofSubmitted[msg.sender] = true;
    }
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        return (proof[0] * proof[1]) == (input[0] * input[1]);
    }
    function takeLoan(uint256 amount) public {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(amount > 0, "Loan amount must be greater than zero");
        loanBalances[msg.sender] += amount;
        totalLoans += amount;
    }
    
    function repayLoan(uint256 amount) public {
        require(loanBalances[msg.sender] >= amount, "Repay amount exceeds loan balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Repayment failed");
        loanBalances[msg.sender] -= amount;
        totalLoans -= amount;
    }
    function getLoanBalance(address borrower) public view returns (uint256) {
        return loanBalances[borrower];
    }
    receive() external payable {}
}