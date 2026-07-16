/*@vulnerable_(SWC: 128)_at_lines: 30*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPWithStorageGasLimitDoS {

    // Structure for storing ZKP proof data
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Nested mapping to simulate large-scale storage operations
    mapping(uint256 => mapping(uint256 => uint256)) public nestedData;
    uint256 public dataCounter = 0;

    // ZKP verification function (simulated)
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Assumes verification of input being equal to 25 (e.g., x^2 == 625)
        if (input[0] == 25) {
            return true;
        } else {
            return false;
        }
    }

    // Function that can consume a high amount of Gas, storing nested data
    function storeLargeNestedData(uint256 rows, uint256 cols) public {
        for (uint256 i = 0; i < rows; i++) {
            for (uint256 j = 0; j < cols; j++) {
                nestedData[i][j] = i * j; // Simulating the storage of large amounts of data
            }
        }
        dataCounter += rows * cols; // Updating data count
    }

    // Combines ZKP verification with a large storage operation that may trigger Gas limits
    function verifyAndStoreNestedData(Proof memory proof, uint256 rows, uint256 cols) public {
        // Perform ZKP verification
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");

        // After verification, proceed with the high-Gas storage operation
        storeLargeNestedData(rows, cols);
    }

    // Function to retrieve stored data
    function getStoredData(uint256 row, uint256 col) public view returns (uint256) {
        return nestedData[row][col];
    }
}
