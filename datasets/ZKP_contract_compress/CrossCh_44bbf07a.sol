pragma solidity ^0.8.0;
interface IMiddleLayer {
    function handleSynPackage(uint8 channelId, bytes memory payload) external returns (bytes memory);
    function handleAckPackage(uint8 channelId, uint64 sequence, bytes memory payload, uint256 callbackGasLimit) external returns (uint256 remainingGas, address refundAddress);
    function handleFailAckPackage(uint8 channelId, uint64 sequence, bytes memory payload, uint256 callbackGasLimit) external returns (uint256 remainingGas, address refundAddress);
}
interface ITokenHub {
    function refundCallbackGasFee(address refundAddress, uint256 refundFee) external;
    function cancelTransferIn(address attacker) external;
}
interface ILightClient {
    function isRelayer(address relayer) external view returns (bool);
    function verifyRelayerAndPackage(uint64 eventTime, bytes calldata payload, bytes calldata blsSignature, uint256 validatorsBitSet) external view returns (bool);
}
interface IRelayerHub {
    function addReward(address relayer, uint256 reward) external;
}
library BytesToTypes {
    function bytesToUint256(uint len, bytes memory b) internal pure returns (uint256) {
        require(b.length >= len, "BytesToTypes: invalid length");
        uint256 number;
        for (uint i = 0; i < len; i++) {
            number = number + uint256(uint8(b[i])) * (2 ** (8 * (len - (i + 1))));
        }
        return number;
    }
    
    function bytesToUint16(uint len, bytes memory b) internal pure returns (uint16) {
        require(b.length >= len, "BytesToTypes: invalid length");
        uint16 number;
        for (uint i = 0; i < len; i++) {
            number = number + uint16(uint8(b[i])) * uint16(2 ** (8 * (len - (i + 1))));
        }
        return number;
    }
}
contract CrossChainZKP {
    
    uint8 public constant SYN_PACKAGE = 0x00;
    uint8 public constant ACK_PACKAGE = 0x01;
    uint8 public constant FAIL_ACK_PACKAGE = 0x02;
    uint256 public constant EMERGENCY_PROPOSAL_EXPIRE_PERIOD = 1 hours;
    uint256 public constant MAX_RELAY_FEE = 1 ether;
    uint32 public chainId;
    uint32 public targetChainId;
    uint256 public relayFee;
    uint256 public minAckRelayFee;
    uint256 public batchSizeForOracle;
    uint256 public callbackGasPrice;
    uint256 public oracleSequence;
    uint256 public txCounter;
    uint256 public previousTxHeight;
    bool public isSuspended;
    mapping(bytes32 => EmergencyProposal) public emergencyProposals;
    mapping(bytes32 => uint16) public quorumMap;
    mapping(uint8 => uint64) public channelSendSequenceMap;
    mapping(uint8 => uint64) public channelReceiveSequenceMap;
    mapping(uint8 => address) public channelHandlerMap;
    mapping(address => mapping(uint8 => bool)) public registeredContractChannelMap;
    struct EmergencyProposal {
        uint16 quorum;
        uint128 expiredAt;
        bytes32 contentHash;
        address[] approvers;
    }
    event CrossChainPackage(
        uint32 srcChainId,
        uint32 dstChainId,
        uint64 indexed oracleSequence,
        uint64 indexed packageSequence,
        uint8 indexed channelId,
        bytes payload
    );
    event ReceivedPackage(uint8 packageType, uint64 indexed packageSequence, uint8 indexed channelId);
    event ProposalSubmitted(
        bytes32 indexed proposalTypeHash,
        address indexed proposer,
        uint128 quorum,
        uint128 expiredAt,
        bytes32 contentHash
    );
    event Suspended(address indexed executor);
    event Reopened(address indexed executor);
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "only EOA");
        _;
    }
    modifier relayFeeCheck(uint256 _relayFee, uint256 _ackRelayFee) {
        require(_relayFee <= MAX_RELAY_FEE, "_relayFee too large");
        require(_ackRelayFee <= MAX_RELAY_FEE, "_ackRelayFee too large");
        _;
    }
    modifier whenNotSuspended() {
        require(!isSuspended, "suspended");
        _;
    }
    modifier whenSuspended() {
        require(isSuspended, "not suspended");
        _;
    }
    constructor(uint32 _targetChainId) {
        require(_targetChainId != 0, "Invalid chain id");
        targetChainId = _targetChainId;
        chainId = uint32(block.chainid);
        relayFee = 25 * 1e13;
        minAckRelayFee = 130 * 1e13;
        batchSizeForOracle = 50;
        callbackGasPrice = 4 gwei;
        oracleSequence = 0;
        previousTxHeight = 0;
        txCounter = 0;
    }
    function encodePayload(
        uint8 packageType,
        uint256 _relayFee,
        uint256 _ackRelayFee,
        bytes memory msgBytes
    ) public view relayFeeCheck(_relayFee, _ackRelayFee) returns (bytes memory) {
        return
            packageType == SYN_PACKAGE
                ? abi.encodePacked(packageType, uint64(block.timestamp), _relayFee, _ackRelayFee, msgBytes)
                : abi.encodePacked(packageType, uint64(block.timestamp), _relayFee, msgBytes);
    }
    function sendSynPackage(
        uint8 channelId,
        bytes calldata msgBytes,
        uint256 _relayFee,
        uint256 _ackRelayFee
    ) external onlyEOA whenNotSuspended {
        uint64 sendSequence = channelSendSequenceMap[channelId];
        _sendPackage(sendSequence, channelId, encodePayload(SYN_PACKAGE, _relayFee, _ackRelayFee, msgBytes));
        sendSequence++;
        channelSendSequenceMap[channelId] = sendSequence;
    }
    function handlePackage(
        bytes calldata _payload,
        uint8 channelId,
        uint64 sequence
    ) external onlyEOA whenNotSuspended {
        require(channelHandlerMap[channelId] != address(0), "Channel is not supported");
        require(sequence == channelReceiveSequenceMap[channelId], "Sequence not in order");
        channelReceiveSequenceMap[channelId]++;
        emit ReceivedPackage(SYN_PACKAGE, sequence, channelId);
    }
    function _sendPackage(uint64 packageSequence, uint8 channelId, bytes memory payload) internal whenNotSuspended {
        if (block.number > previousTxHeight) {
            oracleSequence++;
            txCounter = 1;
            previousTxHeight = block.number;
        } else {
            txCounter++;
            if (txCounter > batchSizeForOracle) {
                oracleSequence++;
                txCounter = 1;
            }
        }
        emit CrossChainPackage(chainId, targetChainId, uint64(oracleSequence), packageSequence, channelId, payload);
    }
    function suspend() external onlyEOA whenNotSuspended {
        isSuspended = true;
        emit Suspended(msg.sender);
    }
    function reopen() external onlyEOA whenSuspended {
        isSuspended = false;
        emit Reopened(msg.sender);
    }
    mapping(address => uint) public tokenBalances;
    function batchTransfer_ReentrancyInBatchTransfer_oa54(address[] calldata recipients, uint[] calldata amounts) external {
        require(recipients.length == amounts.length, "Mismatched input lengths");
        for (uint i = 0; i < recipients.length; i++) {
            require(tokenBalances[msg.sender] >= amounts[i], "Insufficient balance");
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed");
            tokenBalances[msg.sender] -= amounts[i];
        }
    }
    
}