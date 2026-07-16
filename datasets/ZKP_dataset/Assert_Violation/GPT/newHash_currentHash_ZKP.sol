/*@vulnerable_(SWC: 110)_at_lines: 36*/
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

contract ZKPWithHash{
    IZKPVerifier public verifier;
    uint256 public currentHash;

    event ProofVerified(bool success, uint256 indexed newHash);

    constructor(address verifierAddress) {
        verifier = IZKPVerifier(verifierAddress);
    }

    // Function to verify ZKP proof and update the stored hash
    function verifyAndUpdateHash(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        // Calls the ZKP verifier to check if the proof is valid
        bool proofValid = verifier.verifyProof(a, b, c, input);

        // Hashes the input as part of the ZKP process (simulated)
        uint256 newHash = uint256(keccak256(abi.encodePacked(input[0])));

        // Asserts the new hash is greater than the current hash
        assert(newHash > currentHash);

        if (proofValid) {
            // Updates the state with the new hash if proof is valid
            currentHash = newHash;
        }

        emit ProofVerified(proofValid, currentHash);
    }
}
