/*@vulnerable_(SWC: 128)_at_lines: 32*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPRecursiveComputationDoS {

    // Structure required for ZKP verification
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Mapping to store recursive computation results
    mapping(uint256 => uint256) public computationResults;
    uint256 public resultCounter;

    // Simulated ZKP verification function
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Verifies whether the input equals 81 (i.e., x^2 == 81)
        return input[0] == 81;
    }

    // Recursive computation function, calculates factorial and stores results, may lead to high Gas consumption
    function recursiveFactorial(uint256 n) public returns (uint256) {
        if (n == 0 || n == 1) {
            return 1;
        } else {
            uint256 result = n * recursiveFactorial(n - 1);  // Recursive call, gradually calculating factorial
            computationResults[resultCounter] = result;      // Stores the computation result
            resultCounter++;
            return result;
        }
    }

    // Combines ZKP verification and recursive factorial storage operation, may lead to high Gas consumption
    function verifyAndComputeFactorial(Proof memory proof, uint256 n) public {
        // Performs ZKP verification
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");

        // After verification, execute recursive factorial computation and storage
        recursiveFactorial(n);
    }

    // Retrieves stored computation result
    function getResult(uint256 index) public view returns (uint256) {
        require(index < resultCounter, "Index out of bounds");
        return computationResults[index];
    }
}
