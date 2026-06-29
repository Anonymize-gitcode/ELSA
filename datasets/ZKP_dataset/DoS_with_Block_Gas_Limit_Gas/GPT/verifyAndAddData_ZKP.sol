/*@vulnerable_(SWC: 128)_at_lines: 37, 50*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPWithGasLimitDoS {
    // ZKP part: Verifying if the square of an input equals a specific value
    // Assuming we are using zk-SNARK generated proof
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Gas-intensive operations
    mapping(uint256 => uint256) public data;
    uint256 public dataSize;

    // ZKP verification function - demonstration purpose
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Simple ZKP verification logic: check if input[0] equals 4 (i.e., x^2 == 16)
        if (input[0] == 4) {
            return true;
        } else {
            return false;
        }
    }

    // Using ZKP verification to execute a gas-intensive operation
    function verifyAndAddData(Proof memory proof, uint256 iterations) public {
        // First, verify ZKP
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");

        // Perform gas-intensive operation
        for (uint256 i = 0; i < iterations; i++) {
            data[dataSize] = i;
            dataSize++;
        }
    }

    // Intentionally gas-intensive function allowing many iterations, susceptible to gas exhaustion
    function addData(uint256 iterations) public {
        for (uint256 i = 0; i < iterations; i++) {
            data[dataSize] = i;
            dataSize++;
        }
    }
}
