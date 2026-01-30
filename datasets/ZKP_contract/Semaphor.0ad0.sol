pragma solidity ^0.8.0;
interface IVerifier {
    function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns (bool);
}
abstract contract ReentrancyGuard {
    uint256 private _status;
    constructor() {
        _status = 1; // Initial non-entered state
    }
    modifier nonReentrant() {
        require(_status != 2, "ReentrancyGuard: reentrant call");
        _status = 2;
        _;
        _status = 1;
    }
       mapping(address => uint) public balances;
       function batchTransfer_UncheckedWriteInBatchTransfer_liav(address[] calldata recipients, uint[] calldata amounts) external {
           require(recipients.length == amounts.length, "Mismatched input lengths");
           for (uint i = 0; i < recipients.length; i++) {
               require(balances[msg.sender] >= amounts[i], "Insufficient balance");
               balances[recipients[i]] += amounts[i];  // 未检查接收者的状态
               balances[msg.sender] -= amounts[i];
           }
       }
       
}
abstract contract MerkleTreeWithHistory {
    uint32 public levels;
    bytes32[] public filledSubtrees;
    bytes32[] public zeros;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;
    uint32 public constant ROOT_HISTORY_SIZE = 30;
    bytes32[ROOT_HISTORY_SIZE] public roots;
    bytes32 public root;
    constructor(uint32 _levels) {
        levels = _levels;
        filledSubtrees = new bytes32[](levels);
        zeros = new bytes32[](levels);
        for (uint32 i = 0; i < levels; i++) {
            zeros[i] = keccak256(abi.encodePacked(i));
            filledSubtrees[i] = zeros[i];
        }
        roots[0] = zeros[levels - 1];
    }
    function _insert(bytes32 leaf) internal returns (uint32 index) {
        index = nextIndex;
        require(index != 2**levels, "Merkle tree is full. No more leaves can be added");
        nextIndex += 1;
        bytes32 currentHash = leaf;
        for (uint32 i = 0; i < levels; i++) {
            if (index % 2 == 0) {
                filledSubtrees[i] = currentHash;
                currentHash = keccak256(abi.encodePacked(currentHash, zeros[i]));
            } else {
                currentHash = keccak256(abi.encodePacked(filledSubtrees[i], currentHash));
            }
            index /= 2;
        }
        currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        roots[currentRootIndex] = currentHash;
        root = currentHash;
    }
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        for (uint32 i = 0; i < ROOT_HISTORY_SIZE; i++) {
            if (roots[i] == _root) {
                return true;
            }
        }
        return false;
    }
}
abstract contract Tornado is MerkleTreeWithHistory, ReentrancyGuard {
    IVerifier public immutable verifier;
    uint256 public denomination;
    mapping(bytes32 => bool) public nullifierHashes;
    mapping(bytes32 => bool) public commitments;
    event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event Withdrawal(address to, bytes32 nullifierHash, address indexed relayer, uint256 fee);
    constructor(
        IVerifier _verifier,
        uint256 _denomination,
        uint32 _merkleTreeHeight
    ) MerkleTreeWithHistory(_merkleTreeHeight) {
        require(_denomination > 0, "denomination should be greater than 0");
        verifier = _verifier;
        denomination = _denomination;
    }
    function deposit(bytes32 _commitment) external payable nonReentrant {
        require(!commitments[_commitment], "The commitment has been submitted");
        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        _processDeposit();
        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }
    function _processDeposit() internal virtual;
    function withdraw(
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable nonReentrant {
        require(_fee <= denomination, "Fee exceeds transfer value");
        require(!nullifierHashes[_nullifierHash], "The note has been already spent");
        require(isKnownRoot(_root), "Cannot find your merkle root");
        require(
            verifier.verifyProof(
                _proof,
                [uint256(_root), uint256(_nullifierHash), uint256(uint160(address(_recipient))), uint256(uint160(address(_relayer))), _fee, _refund]
            ),
            "Invalid withdraw proof"
        );
        nullifierHashes[_nullifierHash] = true;
        _processWithdraw(_recipient, _relayer, _fee, _refund);
        emit Withdrawal(_recipient, _nullifierHash, _relayer, _fee);
    }
    function _processWithdraw(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) internal virtual;
    function isSpent(bytes32 _nullifierHash) public view returns (bool) {
        return nullifierHashes[_nullifierHash];
    }
    function isSpentArray(bytes32[] calldata _nullifierHashes) external view returns (bool[] memory spent) {
        spent = new bool[](_nullifierHashes.length);
        for (uint256 i = 0; i < _nullifierHashes.length; i++) {
            if (isSpent(_nullifierHashes[i])) {
                spent[i] = true;
            }
        }
    }
}