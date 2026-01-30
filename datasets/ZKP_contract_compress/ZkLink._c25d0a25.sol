pragma solidity ^0.8.0;
address constant L2_DEPLOYER_SYSTEM_CONTRACT_ADDR = address(0x8006);
address constant L2_FORCE_DEPLOYER_ADDR = address(0x8007);
address constant L2_TO_L1_MESSENGER_SYSTEM_CONTRACT_ADDR = address(0x8008);
address constant L2_BOOTLOADER_ADDRESS = address(0x8001);
address constant L2_ETH_TOKEN_SYSTEM_CONTRACT_ADDR = address(0x800a);
address constant L2_KNOWN_CODE_STORAGE_SYSTEM_CONTRACT_ADDR = address(0x8004);
address constant L2_SYSTEM_CONTEXT_SYSTEM_CONTRACT_ADDR = address(0x800b);
bytes32 constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
uint256 constant L2_TO_L1_LOG_SERIALIZE_SIZE = 88;
uint256 constant MAX_L2_TO_L1_LOGS_COMMITMENT_BYTES = 4 + L2_TO_L1_LOG_SERIALIZE_SIZE * 512;
bytes32 constant L2_L1_LOGS_TREE_DEFAULT_LEAF_HASH = 0x72abee45b59e344af8a6e520241c4744aff26ed411f4c4b00f8af09adada43ba;
bytes32 constant DEFAULT_L2_LOGS_TREE_ROOT_HASH = bytes32(0);
uint256 constant PRIORITY_OPERATION_L2_TX_TYPE = 255;
uint256 constant SYSTEM_UPGRADE_L2_TX_TYPE = 254;
uint256 constant MAX_ALLOWED_PROTOCOL_VERSION_DELTA = 100;
uint256 constant PRIORITY_EXPIRATION = 0 days;
uint256 constant COMMIT_TIMESTAMP_NOT_OLDER = 3 days;
uint256 constant COMMIT_TIMESTAMP_APPROXIMATION_DELTA = 1 hours;
uint256 constant PUBLIC_INPUT_SHIFT = 32;
uint256 constant MAX_GAS_PER_TRANSACTION = 80000000;
uint256 constant L1_GAS_PER_PUBDATA_BYTE = 17;
uint256 constant L1_TX_INTRINSIC_L2_GAS = 167157;
uint256 constant L1_TX_INTRINSIC_PUBDATA = 88;
uint256 constant L1_TX_MIN_L2_GAS_BASE = 173484;
uint256 constant L1_TX_DELTA_544_ENCODING_BYTES = 1656;
uint256 constant L1_TX_DELTA_FACTORY_DEPS_L2_GAS = 2473;
uint256 constant L1_TX_DELTA_FACTORY_DEPS_PUBDATA = 64;
uint256 constant MAX_NEW_FACTORY_DEPS = 32;
uint256 constant REQUIRED_L2_GAS_PRICE_PER_PUBDATA = 800;
uint256 constant PACKED_L2_BLOCK_TIMESTAMP_MASK = 0xffffffffffffffffffffffffffffffff;
uint256 constant TX_SLOT_OVERHEAD_L2_GAS = 10000;
uint256 constant MEMORY_OVERHEAD_GAS = 10;
library TransactionValidator {
    function validateL1ToL2Transaction(
        IMailbox.L2CanonicalTransaction memory _transaction,
        bytes memory _encoded,
        uint256 _priorityTxMaxGasLimit,
        uint256 _priorityTxMaxPubdata
    ) internal pure {
        uint256 l2GasForTxBody = getTransactionBodyGasLimit(_transaction.gasLimit, _encoded.length);
        require(l2GasForTxBody <= _priorityTxMaxGasLimit, "ui");
        require(l2GasForTxBody / _transaction.gasPerPubdataByteLimit <= _priorityTxMaxPubdata, "uk");
        require(
            getMinimalPriorityTransactionGasLimit(
                _encoded.length,
                _transaction.factoryDeps.length,
                _transaction.gasPerPubdataByteLimit
            ) <= l2GasForTxBody,
            "up"
        );
    }
    function validateUpgradeTransaction(IMailbox.L2CanonicalTransaction memory _transaction) internal pure {
        require(_transaction.from <= type(uint16).max, "ua");
        require(_transaction.to <= type(uint160).max, "ub");
        require(_transaction.paymaster == 0, "uc");
        require(_transaction.value == 0, "ud");
        require(_transaction.maxFeePerGas == 0, "uq");
        require(_transaction.maxPriorityFeePerGas == 0, "ux");
        require(_transaction.reserved[0] == 0, "ue");
        require(_transaction.reserved[1] <= type(uint160).max, "uf");
        require(_transaction.reserved[2] == 0, "ug");
        require(_transaction.reserved[3] == 0, "uo");
        require(_transaction.signature.length == 0, "uh");
        require(_transaction.paymasterInput.length == 0, "ul");
        require(_transaction.reservedDynamic.length == 0, "um");
    }
    function getMinimalPriorityTransactionGasLimit(
        uint256 _encodingLength,
        uint256 _numberOfFactoryDependencies,
        uint256 _l2GasPricePerPubdata
    ) internal pure returns (uint256) {
        uint256 costForComputation = L1_TX_INTRINSIC_L2_GAS;
        costForComputation += Math.ceilDiv(_encodingLength * L1_TX_DELTA_544_ENCODING_BYTES, 544);
        costForComputation += _numberOfFactoryDependencies * L1_TX_DELTA_FACTORY_DEPS_L2_GAS;
        costForComputation = Math.max(costForComputation, L1_TX_MIN_L2_GAS_BASE);
        uint256 costForPubdata = L1_TX_INTRINSIC_PUBDATA * _l2GasPricePerPubdata;
        costForPubdata += _numberOfFactoryDependencies * L1_TX_DELTA_FACTORY_DEPS_PUBDATA * _l2GasPricePerPubdata;
        return costForComputation + costForPubdata;
    }
    function getTransactionBodyGasLimit(
        uint256 _totalGasLimit,
        uint256 _encodingLength
    ) internal pure returns (uint256 txBodyGasLimit) {
        uint256 overhead = getOverheadForTransaction(_encodingLength);
        require(_totalGasLimit >= overhead, "my");
        unchecked {
            txBodyGasLimit = _totalGasLimit - overhead;
        }
    }
    function getOverheadForTransaction(uint256 _encodingLength) internal pure returns (uint256 batchOverheadForTransaction) {
        batchOverheadForTransaction = TX_SLOT_OVERHEAD_L2_GAS;
        uint256 overheadForLength = MEMORY_OVERHEAD_GAS * _encodingLength;
        batchOverheadForTransaction = Math.max(batchOverheadForTransaction, overheadForLength);
    }
}
library Merkle {
    using UncheckedMath for uint256;
    function calculateRoot(
        bytes32[] calldata _path,
        uint256 _index,
        bytes32 _itemHash
    ) internal pure returns (bytes32) {
        uint256 pathLength = _path.length;
        require(pathLength > 0, "xc");
        require(pathLength < 256, "bt");
        require(_index < (1 << pathLength), "px");
        bytes32 currentHash = _itemHash;
        for (uint256 i; i < pathLength; i = i.uncheckedInc()) {
            currentHash = (_index % 2 == 0)
                ? _efficientHash(currentHash, _path[i])
                : _efficientHash(_path[i], currentHash);
            _index /= 2;
        }
        return currentHash;
    }
    function _efficientHash(bytes32 _lhs, bytes32 _rhs) internal pure returns (bytes32 result) {
        assembly {
            mstore(0x00, _lhs)
            mstore(0x20, _rhs)
            result := keccak256(0x00, 0x40)
        }
    }
}
library UncheckedMath {
    function uncheckedInc(uint256 _number) internal pure returns (uint256) {
        unchecked {
            return _number + 1;
        }
    }
    function uncheckedAdd(uint256 _lhs, uint256 _rhs) internal pure returns (uint256) {
        unchecked {
            return _lhs + _rhs;
        }
    }
}
library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }
}
interface IMailbox {
    struct L2CanonicalTransaction {
        uint256 txType;
        uint256 from;
        uint256 to;
        uint256 gasLimit;
        uint256 gasPerPubdataByteLimit;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        uint256 paymaster;
        uint256 nonce;
        uint256 value;
        uint256[4] reserved;
        bytes data;
        bytes signature;
        uint256[] factoryDeps;
        bytes paymasterInput;
        bytes reservedDynamic;
    }
}
contract ZkLink {
    using UncheckedMath for uint256;
    function exampleFunction() external pure returns (string memory) {
        return "Contract compiled successfully!";
    }
    function withdrawFixedAmount_UnprotectedFixedAmountWithdraw_4bhz(uint amount) public {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
}