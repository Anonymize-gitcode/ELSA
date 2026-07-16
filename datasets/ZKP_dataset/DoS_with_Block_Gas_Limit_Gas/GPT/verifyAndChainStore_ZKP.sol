/*@vulnerable_(SWC: 128)_at_lines: 34*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPChainStorageDoS {

    // Structure for ZKP verification data
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }

    // Structure for storing chain data
    struct Node {
        uint256 data;
        uint256 next;
    }

    // Mapping to store chained nodes
    mapping(uint256 => Node) public nodeList;
    uint256 public nodeCounter;

    // ZKP verification function
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        // Simulated verification, assuming input[0] equals 25 for success (x^2 == 625)
        return input[0] == 25;
    }

    // Chain storage function, high Gas consumption
    function chainStoreData(uint256 length) public {
        for (uint256 i = 0; i < length; i++) {
            nodeList[nodeCounter] = Node(i, nodeCounter + 1);  // Creating and storing chained nodes
            nodeCounter++;
        }
    }

    // Combines ZKP verification and chain storage operation, potentially triggering high Gas consumption
    function verifyAndChainStore(Proof memory proof, uint256 length) public {
        // ZKP verification
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");

        // After successful verification, perform chain storage
        chainStoreData(length);
    }

    // Retrieve data from a specific chained node
    function getNodeData(uint256 nodeIndex) public view returns (uint256 data, uint256 next) {
        require(nodeIndex < nodeCounter, "Node index out of bounds");
        Node memory node = nodeList[nodeIndex];
        return (node.data, node.next);
    }

    // Get the total count of chained nodes
    function getNodeCount() public view returns (uint256) {
        return nodeCounter;
    }
}
