/*@vulnerable_(SWC:110)_at_lines: 28*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZKPVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPContractWithSWC110 {
    IZKPVerifier public verifier;
    uint public result;
    
    event ProofVerified(bool success, uint indexed result);

    constructor(address _verifier) {
        verifier = IZKPVerifier(_verifier);
    }

    // Verifies the ZKP proof
    function verifyZKP(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        // Calls the ZKP verifier to validate the proof
        bool proofVerified = verifier.verifyProof(a, b, c, input);

        // Verifies that the input meets the condition, failing otherwise
        assert(input[0] > 1);  // Unsafe condition that may lead to assert failure
        
        if (proofVerified) {
            result = input[0];
        }

        emit ProofVerified(proofVerified, result);
    }
}
