/*@vulnerable_(SWC: 128)_at_lines: 37*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPChainArrayStorageDoS {

    // Structure needed for ZKP verification
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Structure to store the chained arrays
    struct ChainArray {
        uint256[] values;
        uint256 next;
    }

    // Mapping to store the chain structure
    mapping(uint256 => ChainArray) public chainArrayStorage;
    uint256 public chainArrayCounter;

    // Simulated ZKP verification function
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Assume we are verifying if input[0] equals 99, simulating ZKP verification
        return input[0] == 99;
    }

    // Create and store chained arrays, may lead to high Gas consumption
    function createChainArray(uint256 arraySize, uint256 chainLength) public {
        for (uint256 i = 0; i < chainLength; i++) {
            uint256[] memory newArray = new uint256[](arraySize);
            for (uint256 j = 0; j < arraySize; j++) {
                newArray[j] = j;  // Filling the array
            }
            chainArrayStorage[chainArrayCounter] = ChainArray(newArray, chainArrayCounter + 1);
            chainArrayCounter++;
        }
    }

    // Combine ZKP verification and chained array storage, may cause high Gas consumption
    function verifyAndStoreChainArray(Proof memory proof, uint256 arraySize, uint256 chainLength) public {
        // Perform ZKP verification
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");

        // After successful verification, perform chained array storage
        createChainArray(arraySize, chainLength);
    }

    // Retrieve values from a chain node in the array
    function getChainArray(uint256 index) public view returns (uint256[] memory values, uint256 next) {
        require(index < chainArrayCounter, "Index out of bounds");
        ChainArray memory chainNode = chainArrayStorage[index];
        return (chainNode.values, chainNode.next);
    }

    // Get the total number of chain arrays
    function getChainArrayCount() public view returns (uint256) {
        return chainArrayCounter;
    }
}
