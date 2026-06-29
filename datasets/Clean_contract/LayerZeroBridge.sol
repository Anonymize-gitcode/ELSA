// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Importing necessary interfaces and libraries
interface ILayerZeroReceiver {
    function lzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) external;
}

interface ILayerZeroEndpoint {
    function send(uint16 dstChainId, bytes calldata destination, bytes calldata payload, address payable refundAddress, address zroPaymentAddress, bytes calldata adapterParams) external payable;
    function estimateFees(uint16 dstChainId, address userApplication, bytes calldata payload, bool payInZRO, bytes calldata adapterParams) external view returns (uint nativeFee, uint zroFee);
}

interface ILayerZeroUserApplicationConfig {
    function setConfig(uint16 version, uint16 chainId, uint configType, bytes calldata config) external;
    function setSendVersion(uint16 version) external;
    function setReceiveVersion(uint16 version) external;
    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress) external;
}

interface IZKPVerifier {
    function verifyProof(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[1] memory input) external view returns (bool);
}

interface ISyncService {
    function sendSyncHash(bytes32 syncHash) external payable;
    function confirmBlock(uint8 destZkLinkChainId, uint32 blockNumber) external payable;
}

abstract contract ReentrancyGuard {
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract ZKPLayerZeroBridge is ReentrancyGuard, ILayerZeroReceiver, ILayerZeroUserApplicationConfig, ISyncService {
    IZKPVerifier public zkpVerifier;
    ILayerZeroEndpoint public endpoint;

    mapping(uint16 => bytes) public destinations;
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;
    
    event MessageFailed(uint16 srcChainId, bytes srcAddress, uint64 nonce, bytes payload);
    event SyncHashSent(bytes32 syncHash);
    event BlockConfirmed(uint32 blockNumber);
    
    modifier onlyEndpoint {
        require(msg.sender == address(endpoint), "Require endpoint");
        _;
    }

    constructor(ILayerZeroEndpoint _endpoint, IZKPVerifier _zkpVerifier) {
        endpoint = _endpoint;
        zkpVerifier = _zkpVerifier;
        initializeReentrancyGuard();
    }

    /// @notice Send a sync hash with zk-SNARK proof
    /// @param syncHash Sync hash to send
    /// @param a zk-SNARK proof part a
    /// @param b zk-SNARK proof part b
    /// @param c zk-SNARK proof part c
    /// @param input zk-SNARK proof input
    function sendSyncHashWithProof(
        bytes32 syncHash,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external payable {
        bool isValid = zkpVerifier.verifyProof(a, b, c, input);
        require(isValid, "Invalid zk-SNARK proof");

        uint16 dstChainId = 1; // Assuming destination chain ID is 1 (replace with actual logic)
        bytes memory payload = abi.encode(syncHash, a, b, c, input);
        bytes memory path = abi.encodePacked(destinations[dstChainId], address(this));

        endpoint.send{value: msg.value}(dstChainId, path, payload, payable(msg.sender), address(0), new bytes(0));

        emit SyncHashSent(syncHash);
    }

    /// @notice Confirm a block with zk-SNARK proof
    /// @param blockNumber The block number to confirm
    /// @param a zk-SNARK proof part a
    /// @param b zk-SNARK proof part b
    /// @param c zk-SNARK proof part c
    /// @param input zk-SNARK proof input
    function confirmBlockWithProof(
        uint32 blockNumber,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external payable {
        bool isValid = zkpVerifier.verifyProof(a, b, c, input);
        require(isValid, "Invalid zk-SNARK proof");

        uint16 dstChainId = 1; // Assuming destination chain ID is 1 (replace with actual logic)
        bytes memory payload = abi.encode(blockNumber, a, b, c, input);
        bytes memory path = abi.encodePacked(destinations[dstChainId], address(this));

        endpoint.send{value: msg.value}(dstChainId, path, payload, payable(msg.sender), address(0), new bytes(0));

        emit BlockConfirmed(blockNumber);
    }

    function _nonblockingLzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) internal {
        (bytes32 syncHash, uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[1] memory input) = abi.decode(payload, (bytes32, uint[2], uint[2][2], uint[2], uint[1]));

        bool isValid = zkpVerifier.verifyProof(a, b, c, input);
        require(isValid, "Invalid zk-SNARK proof");

        // Process sync hash or block confirmation
        // Add custom logic based on the decoded payload here
    }

    /// @notice Retry failed message
    function retryMessage(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) external payable {
        bytes32 payloadHash = failedMessages[srcChainId][srcAddress][nonce];
        require(payloadHash != bytes32(0), "No stored message");
        require(keccak256(payload) == payloadHash, "Invalid payload");

        failedMessages[srcChainId][srcAddress][nonce] = bytes32(0);
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    /// @notice Handle LayerZero incoming message
    function lzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) external override onlyEndpoint nonReentrant {
        bytes memory path = abi.encodePacked(destinations[srcChainId], address(this));
        require(keccak256(srcAddress) == keccak256(path), "Invalid source address");

        try this._nonblockingLzReceive(srcChainId, srcAddress, nonce, payload) {
        } catch {
            failedMessages[srcChainId][srcAddress][nonce] = keccak256(payload);
            emit MessageFailed(srcChainId, srcAddress, nonce, payload);
        }
    }

    /// @notice Set the destination chain and contract
    function setDestination(uint16 chainId, bytes calldata contractAddress) external {
        destinations[chainId] = contractAddress;
    }

    // Implementation of ILayerZeroUserApplicationConfig functions for LayerZero configuration
    function setConfig(uint16 version, uint16 chainId, uint configType, bytes calldata config) external override {}
    function setSendVersion(uint16 version) external override {}
    function setReceiveVersion(uint16 version) external override {}
    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress) external override {}
}
