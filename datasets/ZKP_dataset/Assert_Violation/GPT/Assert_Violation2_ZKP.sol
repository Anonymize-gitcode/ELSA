/*@vulnerable_(SWC: 110)_at_lines: 22*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZKVerifier {
    function verifyProof(
        bytes memory proof,
        uint256[1] memory input
    ) external returns (bool);
}

contract ZKPWithSWC110Vulnerability {
    IZKVerifier public verifier;
    uint public state;
    
    event ZKPVerified(bool success, uint indexed newState);

    constructor(address verifierAddress) {
        verifier = IZKVerifier(verifierAddress);
    }

    // This function verifies a ZKP proof and updates the state if verified
    function verifyAndUpdateState(bytes memory proof, uint256[1] memory input) public {
        // Call the external verifier to check the ZKP proof
        bool verified = verifier.verifyProof(proof, input);

        // Assertion: Input value must equal the current state + 2
        assert(input[0] == state + 2);

        if (verified) {
            // If the proof is valid, update the contract state
            state = input[0];
        }

        emit ZKPVerified(verified, state);
    }
}
