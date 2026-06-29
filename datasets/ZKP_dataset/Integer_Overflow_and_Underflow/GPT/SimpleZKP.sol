/*@vulnerable_(SWC: 101)_at_lines: 36*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleZKP {
    address public verifier;  // The verifier who checks the proof
    mapping(address => bool) public proofsVerified;

    constructor() {
        verifier = msg.sender; // Set the contract deployer as the verifier
    }

    // This function simulates submitting a ZKP proof for verification
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Proof verification failed");

        // Mark the proof as verified
        proofsVerified[msg.sender] = true;
    }

    // Simulated zero-knowledge proof verification function
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal view returns (bool) {
        // A simple mock verification logic for demonstration purposes
        // In a real ZKP system, this would involve more complex cryptographic checks
        return (proof[0] + proof[1]) == (input[0] + input[1]);
    }

    // Withdraw function where the SWC-101 vulnerability exists
    /*@vulnerable_(SWC: 101)_at_lines: 36*/
    function withdrawFunds(uint256 amount) public {
        require(proofsVerified[msg.sender], "Proof not verified");
        require(amount <= address(this).balance, "Insufficient contract balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Updating the state after the external call, making it vulnerable to reentrancy attacks
        proofsVerified[msg.sender] = false;
    }

    // Function to allow the contract to receive Ether
    receive() external payable {}
}
