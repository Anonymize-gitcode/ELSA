/*@vulnerable_(SWC: 107)_at_lines: 25*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPTimeLockVulnerable {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockTime;  // Stores withdrawal lock time for each user
    IVerifier public verifier;

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
    }

    // Deposit function
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Users can request a withdrawal, which requires ZKP and time lock validation
    function requestWithdraw(uint256 _amount, bytes memory proof, uint256[2] memory input) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(block.timestamp >= lockTime[msg.sender], "Withdrawal is locked");

        // ZKP validation
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // External call before state update
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        // State update: Update balance and lock time after successful withdrawal
        balances[msg.sender] -= _amount;
        lockTime[msg.sender] = block.timestamp + 1 days;  // Lock for 24 hours after withdrawal
    }

    // Function allowing users to check when they can withdraw again
    function getRemainingLockTime() public view returns (uint256) {
        if (block.timestamp >= lockTime[msg.sender]) {
            return 0;
        } else {
            return lockTime[msg.sender] - block.timestamp;
        }
    }
}
