/*@vulnerable_(SWC: 128)_at_lines: 32*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPVulnerable {
    
    // Structure for ZKP-related data
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    uint256 public largeNumber = 0;

    // ZKP verification function (simulated, actual logic should be generated using a ZKP library)
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Simulate the verification to check if input[0] equals 9 (i.e., x^2 == 81)
        if (input[0] == 9) {
            return true;
        } else {
            return false;
        }
    }

    // Recursive function with high Gas consumption, potentially leading to DoS risks
    function recursiveAdd(uint256 depth) public {
        if (depth == 0) {
            largeNumber++;
        } else {
            recursiveAdd(depth - 1);
        }
    }

    // Uses ZKP verification and recursive operation, potentially triggering SWC-128 vulnerability
    function verifyAndRecursiveAdd(Proof memory proof, uint256 depth) public {
        // Verify the ZKP proof
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid proof");

        // After verification, execute recursive operation with increasing Gas consumption based on depth
        recursiveAdd(depth);
    }

    // Regular addition operation, allowing users to specify complexity
    function complexAdd(uint256 iterations) public {
        for (uint256 i = 0; i < iterations; i++) {
            largeNumber++;
        }
    }
}
