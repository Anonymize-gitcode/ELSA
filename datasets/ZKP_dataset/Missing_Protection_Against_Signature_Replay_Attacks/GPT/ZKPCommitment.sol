/*@vulnerable_(SWC: 121)_at_lines: 55*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPCommitment {
    address public verifier;

    // A structure for a simple ZKP commitment scheme
    struct CommitmentProof {
        uint256 commitment;
        uint256 secret;
        uint256 nonce;
    }

    event CommitmentVerified(address indexed prover, bool success);

    // Constructor sets the verifier address
    constructor() {
        verifier = msg.sender;
    }

    // Function to verify a commitment proof
    function verifyCommitment(CommitmentProof memory proof) public returns (bool) {
        // Simple ZKP check: hash(secret, nonce) should match the commitment
        bool success = (proof.commitment == uint256(keccak256(abi.encodePacked(proof.secret, proof.nonce))));
        emit CommitmentVerified(msg.sender, success);
        return success;
    }

    // Function to change the verifier
    function changeVerifier(address newVerifier) public {
        require(msg.sender == verifier, "Only the verifier can change the verifier");
        verifier = newVerifier;
    }

    // Function to withdraw Ether from the contract, only the verifier can do so
    function withdrawEther() public {
        require(msg.sender == verifier, "Only the verifier can withdraw");
        payable(verifier).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 55*/
    // Fallback function allowing Ether transfers without restrictions
    fallback() external payable {
        // Ether is accepted without any checks or restrictions
    }

    // Vulnerable receive function
    receive() external payable {
        // Ether can be sent to the contract without any restrictions
    }
}
