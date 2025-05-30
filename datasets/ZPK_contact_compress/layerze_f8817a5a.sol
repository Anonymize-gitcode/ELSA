pragma solidity ^0.8.0;
library PoseidonT3 {
    function hash(uint256[2] memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input[0], input[1])));
    }
}
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
struct LeanIMTData {
    uint256 size;
    uint256 depth;
    mapping(uint256 => uint256) sideNodes;
    mapping(uint256 => uint256) leaves;
}
library InternalLeanIMT {
    string constant LEAF_GREATER_THAN_SNARK_SCALAR_FIELD = "Leaf value exceeds SNARK scalar field.";
    string constant LEAF_CANNOT_BE_ZERO = "Leaf cannot be zero.";
    string constant LEAF_ALREADY_EXISTS = "Leaf already exists.";
    function _insert(LeanIMTData storage self, uint256 leaf) internal returns (uint256) {
        if (leaf >= SNARK_SCALAR_FIELD) {
            revert(LEAF_GREATER_THAN_SNARK_SCALAR_FIELD);
        } else if (leaf == 0) {
            revert(LEAF_CANNOT_BE_ZERO);
        } else if (_has(self, leaf)) {
            revert(LEAF_ALREADY_EXISTS);
        }
        uint256 index = self.size;
        uint256 treeDepth = self.depth;
        if (2 ** treeDepth < index + 1) {
            ++treeDepth;
        }
        self.depth = treeDepth;
        uint256 node = leaf;
        for (uint256 level = 0; level < treeDepth; ) {
            if ((index >> level) & 1 == 1) {
                node = PoseidonT3.hash([self.sideNodes[level], node]);
            } else {
                self.sideNodes[level] = node;
            }
            unchecked {
                ++level;
            }
        }
        self.size = ++index;
        self.sideNodes[treeDepth] = node;
        self.leaves[leaf] = index;
        return node;
    }
    function _has(LeanIMTData storage self, uint256 leaf) internal view returns (bool) {
        return self.leaves[leaf] != 0;
    }
    function _root(LeanIMTData storage self) internal view returns (uint256) {
        return self.sideNodes[self.depth];
    }
}
abstract contract NonblockingLzApp {
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;
    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal virtual;
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;
    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public payable virtual {
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "No stored message");
        require(keccak256(_payload) == payloadHash, "Invalid payload");
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
       uint256 private internalBalance;
       function getInternalBalance_PrivateVariablePublicGetter_q8al() public view returns (uint256) {
           return internalBalance;
       }
       
}
interface ILayerZeroEndpoint {
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParams
    ) external view returns (uint nativeFee, uint zroFee);
}
interface IZKPVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external view returns (bool);
}
contract ZKPCrossChainMerkleTree is NonblockingLzApp {
    using InternalLeanIMT for LeanIMTData;
    LeanIMTData public merkleTree; // Merkle 树存储结构
    IZKPVerifier public zkpVerifier; // ZKP 验证器合约地址
    ILayerZeroEndpoint public lzEndpoint;  // LayerZero 跨链端点
    constructor(address _zkpVerifier, address _lzEndpoint) {
        zkpVerifier = IZKPVerifier(_zkpVerifier);
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }
    event MerkleLeafAdded(uint256 indexed leaf, uint256 indexed newRoot);
    event CrossChainMerkleUpdate(uint16 indexed srcChainId, bytes indexed srcAddress, uint64 indexed nonce, uint256 newLeaf);
    event ZKPVerificationFailed(uint256 indexed leaf); // ZKP 验证失败事件
    function addLeafWithProof(
        uint256 newLeaf,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        bool isValid = zkpVerifier.verifyProof(a, b, c, input);
        require(isValid, "Invalid ZKP proof");
        uint256 newRoot = merkleTree._insert(newLeaf);
        emit MerkleLeafAdded(newLeaf, newRoot);
    }
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (uint256 newLeaf, uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[1] memory input) = abi.decode(_payload, (uint256, uint[2], uint[2][2], uint[2], uint[1]));
        bool isValid = zkpVerifier.verifyProof(a, b, c, input);
        if (isValid) {
            uint256 newRoot = merkleTree._insert(newLeaf);
            emit CrossChainMerkleUpdate(_srcChainId, _srcAddress, _nonce, newLeaf);
        } else {
            emit ZKPVerificationFailed(newLeaf);
        }
    }
    function sendCrossChainMerkleUpdate(
        uint16 _dstChainId,
        uint256 newLeaf,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable {
        bytes memory payload = abi.encode(newLeaf, a, b, c, input);
        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
    }
    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal override {
        lzEndpoint.send{value: _nativeFee}(
            _dstChainId,
            abi.encodePacked(address(this)),
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }
}