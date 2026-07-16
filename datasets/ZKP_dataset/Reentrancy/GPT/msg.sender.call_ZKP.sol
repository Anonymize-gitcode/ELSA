/*@vulnerable_(SWC: 107)_at_lines: 24*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ZKP Verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint[2] memory input) external returns (bool);
}

contract ZKPWithReentrancyVulnerability {
    mapping(address => uint256) public balances;
    IVerifier public verifier;

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
    }

    // Function to deposit Ether into the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Function to withdraw Ether with ZKP verification
    function withdraw(uint256 _amount, bytes memory proof, uint[2] memory input) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        // Step 1: Zero-knowledge proof verification
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // Step 2: Sends the requested amount to the user
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        // Step 3: Updates the user's balance after the external call
        balances[msg.sender] -= _amount;
    }
}
