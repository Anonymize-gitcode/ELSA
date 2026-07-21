/*@vulnerable_(SWC: 107)_at_lines: 27*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ZKP Verification Interface
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPVulnerableReentrancy {
    mapping(address => uint256) public balances;
    IVerifier public verifier;

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
    }

    // Deposit function: stores user's ether in the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Withdraw function with reentrancy vulnerability
    // Users must prove eligibility via ZKP to withdraw funds
    function withdraw(uint256 _amount, bytes memory proof, uint256[2] memory input) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Step 1: ZKP verification
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // Step 2: External call, transferring funds to user
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        // Step 3: Update balance
        balances[msg.sender] -= _amount;
    }
}
