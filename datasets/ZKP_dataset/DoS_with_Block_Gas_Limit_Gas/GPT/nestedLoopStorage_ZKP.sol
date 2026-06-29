/*@vulnerable_(SWC: 128)_at_lines: 33*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPNestedLoopStorageDoS {

    // Structure for ZKP verification
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Mapping to store computation results
    mapping(uint256 => uint256) public storageData;
    uint256 public storageCounter;

    // Simulated ZKP verification function
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Simulated verification logic, assuming input[0] passes verification when it equals 256
        return input[0] == 256;
    }

    // Data storage using nested loops, potentially causing high Gas consumption
    function nestedLoopStorage(uint256 outerLoops, uint256 innerLoops) public {
        for (uint256 i = 0; i < outerLoops; i++) {
            for (uint256 j = 0; j < innerLoops; j++) {
                storageData[storageCounter] = i * j;  // Storing data
                storageCounter++;
            }
        }
    }

    // Combines ZKP verification and nested loop storage operations, potentially causing high Gas consumption
    function verifyAndStoreData(Proof memory proof, uint256 outerLoops, uint256 innerLoops) public {
        // Perform ZKP verification
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");

        // After verification, perform nested loop storage operations
        nestedLoopStorage(outerLoops, innerLoops);
    }

    // Retrieve a specific stored value
    function getData(uint256 index) public view returns (uint256) {
        require(index < storageCounter, "Index out of bounds");
        return storageData[index];
    }

    // Retrieve the total number of stored entries
    function getStorageCount() public view returns (uint256) {
        return storageCounter;
    }
}
