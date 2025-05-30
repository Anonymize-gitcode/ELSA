pragma solidity ^0.8.0;
contract ZKPChainStorageDoS {
    struct Proof {
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
        uint[1] input;
    }
    struct Node {
        uint256 data;
        uint256 next;
    }
    mapping(uint256 => Node) public nodeList;
    uint256 public nodeCounter;
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public pure returns (bool) {
        return input[0] == 25;
    }
    function chainStoreData(uint256 length) public {
        for (uint256 i = 0; i < length; i++) {
            nodeList[nodeCounter] = Node(i, nodeCounter + 1);  // Creating and storing chained nodes
            nodeCounter++;
        }
    }
    function verifyAndChainStore(Proof memory proof, uint256 length) public {
        require(verifyProof(proof.a, proof.b, proof.c, proof.input), "Invalid ZKP proof");
        chainStoreData(length);
    }
    function getNodeData(uint256 nodeIndex) public view returns (uint256 data, uint256 next) {
        require(nodeIndex < nodeCounter, "Node index out of bounds");
        Node memory node = nodeList[nodeIndex];
        return (node.data, node.next);
    }
    function getNodeCount() public view returns (uint256) {
        return nodeCounter;
    }
}