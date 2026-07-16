/*@vulnerable_(SWC: 128)_at_lines: 35*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPArrayFillerDoS {

    // Structure for ZKP-related data
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Dynamic array for storing large amounts of data
    uint256[] public dynamicArray;
    uint256 public arrayCounter;

    // Simulated ZKP verification function
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Simulated verification condition, checking if input[0] equals 100 (assuming x^2 == 10000)
        return input[0] == 100;
    }

    // High Gas-consuming dynamic array filling function
    function fillDynamicArray(uint256 numElements) public {
        for (uint256 i = 0; i < numElements; i++) {
            dynamicArray.push(i * arrayCounter);  // Fills the array, causing Gas consumption to grow rapidly
            arrayCounter++;
        }
    }

    // Combines ZKP verification and dynamic array filling, potentially triggering high Gas consumption
    function verifyAndFillArray(Proof memory proof, uint256 numElements) public {
        // ZKP verification
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "ZKP proof failed");

        // After verification, fill the dynamic array, consuming Gas
        fillDynamicArray(numElements);
    }

    // Retrieves a value from the array at a specific index
    function getArrayElement(uint256 index) public view returns (uint256) {
        require(index < dynamicArray.length, "Index out of bounds");
        return dynamicArray[index];
    }

    // Retrieves the length of the dynamic array
    function getArrayLength() public view returns (uint256) {
        return dynamicArray.length;
    }
}
