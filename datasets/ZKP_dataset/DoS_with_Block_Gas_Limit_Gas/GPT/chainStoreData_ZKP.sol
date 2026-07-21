/*@vulnerable_(SWC: 128)_at_lines: 37*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPChainDoSVulnerable {

    // Structure for ZKP-related data
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Mapping for storing large amounts of data
    mapping(uint256 => uint256) public storageChain;
    uint256 public storageCounter = 0;

    // ZKP verification function (simulated)
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Simulate ZKP verification, checking if input[0] equals 49 (verifying x^2 == 49)
        return input[0] == 49;
    }

    // Function for storing data in a chain, consuming high Gas
    function chainStoreData(uint256 iterations, uint256 complexity) public {
        for (uint256 i = 0; i < iterations; i++) {
            uint256 data = i;
            for (uint256 j = 0; j < complexity; j++) {
                data = data * j + 1;  // Increasing computational complexity
            }
            storageChain[storageCounter] = data;
            storageCounter++;
        }
    }

    // Combines ZKP verification and chain storage operations, potentially triggering high Gas consumption
    function verifyAndChainStore(Proof memory proof, uint256 iterations, uint256 complexity) public {
        // Perform ZKP verification
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");

        // After verification, perform high-Gas storage operations
        chainStoreData(iterations, complexity);
    }

    // Retrieves stored data by index
    function getStoredData(uint256 index) public view returns (uint256) {
        return storageChain[index];
    }
}
