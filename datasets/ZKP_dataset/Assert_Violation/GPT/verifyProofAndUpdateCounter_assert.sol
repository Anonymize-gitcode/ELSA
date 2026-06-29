/*@vulnerable_(SWC: 110)_at_lines: 36*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZeroKnowledgeVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithSWC110Counter {
    IZeroKnowledgeVerifier public verifier;
    uint256 public counter;

    event ProofVerified(bool success, uint256 indexed newCounter);

    constructor(address verifierAddress) {
        verifier = IZeroKnowledgeVerifier(verifierAddress);
        counter = 0;
    }

    // Function to verify a zero-knowledge proof and update a counter
    function verifyProofAndUpdateCounter(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        // Verify the zero-knowledge proof using the verifier
        bool proofValid = verifier.verifyProof(a, b, c, input);

        // Increment the counter if the proof is valid
        if (proofValid) {
            counter += input[0];  // Increments the counter by the input value
        }

        // Assert that counter should not exceed 1000
        assert(counter <= 1000);  // This assumption may be unsafe

        emit ProofVerified(proofValid, counter);
    }
}
