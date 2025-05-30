pragma solidity ^0.8.0;
interface IArbitrator {
    function isRelayerActive(address relayer) external view returns (bool);
}
interface IMailbox {
    function requestL2Transaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        bytes[] memory _factoryDeps,
        address _refundRecipient
    ) external payable returns (bytes32);
    function l2TransactionBaseCost(
        uint256 _gasPrice,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external view returns (uint256);
}
abstract contract BaseGateway {
    IArbitrator public immutable ARBITRATOR;
    address public remoteGateway;
    modifier onlyArbitrator() {
        require(msg.sender == address(ARBITRATOR), "Not arbitrator");
        _;
    }
    constructor(IArbitrator _arbitrator) {
        ARBITRATOR = _arbitrator;
    }
    function getRemoteGateway() external view returns (address) {
        return remoteGateway;
    }
    function setRemoteGateway(address _remoteGateway) external onlyArbitrator {
        require(remoteGateway == address(0), "Already initialized");
        remoteGateway = _remoteGateway;
    }
        address public owner;
        function transferOwnership_UnrestrictedOwnershipTransfer_gc5y(address _newOwner) public {
            owner = _newOwner;
        }
        
}
contract ZkSyncL1Gateway is BaseGateway {
    IMailbox public immutable MESSAGE_SERVICE;
    mapping(uint256 => mapping(uint256 => bool)) public isMessageFinalized;
    mapping(bytes32 => bytes32) public executedMessage;
    event RetryFailedMessage(bytes32 failedL2TxHash, bytes32 replacedL2TxHash);
    modifier onlyRelayer() {
        require(ARBITRATOR.isRelayerActive(msg.sender), "Not relayer");
        _;
    }
    constructor(IArbitrator _arbitrator, IMailbox _messageService) BaseGateway(_arbitrator) {
        MESSAGE_SERVICE = _messageService;
    }
    function sendMessage(
        uint256 _value,
        bytes calldata _callData,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit
    ) external payable onlyArbitrator {
        bytes memory executeData = abi.encodeWithSignature("claimMessageCallback(uint256,bytes)", _value, _callData);
        bytes32 messageHash = keccak256(executeData);
        uint256 baseCost = MESSAGE_SERVICE.l2TransactionBaseCost(tx.gasprice, _l2GasLimit, _l2GasPerPubdataByteLimit);
        uint256 totalValue = baseCost + _value;
        uint256 leftMsgValue = msg.value - totalValue;
        bytes32 l2TxHash = MESSAGE_SERVICE.requestL2Transaction{value: totalValue}(
            remoteGateway,
            _value,
            executeData,
            _l2GasLimit,
            _l2GasPerPubdataByteLimit,
            new bytes[](0),  // Corrected to an empty bytes[] array
            remoteGateway
        );
        executedMessage[l2TxHash] = messageHash;
        if (leftMsgValue > 0) {
            (bool success, ) = tx.origin.call{value: leftMsgValue}("");
            require(success, "Return excess fee failed");
        }
    }
    function retryFailedMessage(
        bytes calldata _executeData,
        uint256 _l2GasLimit,
        uint256 _l2GasPerPubdataByteLimit,
        address _refundRecipient,
        bytes32 _failedL2TxHash
    ) external payable onlyRelayer {
        bytes32 messageHash = keccak256(_executeData);
        require(executedMessage[_failedL2TxHash] == messageHash, "Invalid message");
        delete executedMessage[_failedL2TxHash];
        bytes32 replacedL2TxHash = MESSAGE_SERVICE.requestL2Transaction{value: msg.value}(
            remoteGateway,
            0,
            _executeData,
            _l2GasLimit,
            _l2GasPerPubdataByteLimit,
            new bytes[](0),  // Corrected to an empty bytes[] array
            _refundRecipient
        );
        executedMessage[replacedL2TxHash] = messageHash;
        emit RetryFailedMessage(_failedL2TxHash, replacedL2TxHash);
    }
}