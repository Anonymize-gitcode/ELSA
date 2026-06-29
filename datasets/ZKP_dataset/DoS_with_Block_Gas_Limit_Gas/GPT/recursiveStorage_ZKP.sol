/*@vulnerable_(SWC: 128)_at_lines: 33*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPRecursionStorageDoS {

    // Structure for ZKP verification
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Mapping to store recursive results
    mapping(uint256 => uint256) public recursiveResults;
    uint256 public recursionCounter;

    // Simulated ZKP verification function
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Simple verification, passing if input[0] equals 16 (x^2 == 16)
        return input[0] == 16;
    }

    // Recursive calculation and storing results, which leads to high Gas consumption
    function recursiveStorage(uint256 n) public returns (uint256) {
        if (n == 0) {
            return 1;
        } else {
            uint256 result = n * recursiveStorage(n - 1);  // Recursive call
            recursiveResults[recursionCounter] = result;   // Storing each step result
            recursionCounter++;
            return result;
        }
    }

    // Combines ZKP verification and recursive storage, potentially causing high Gas consumption
    function verifyAndRecursiveStore(Proof memory proof, uint256 n) public {
        // Verifying ZKP proof
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");

        // After verification, perform recursive storage
        recursiveStorage(n);
    }

    // View recursive storage results
    function getRecursiveResult(uint256 index) public view returns (uint256) {
        return recursiveResults[index];
    }
}
