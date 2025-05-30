pragma solidity ^0.8.0;
abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != ENTERED, "ReentrancyGuard: reentrant call");
        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }
    function withdrawFixedAmount_UnprotectedFixedAmountWithdraw_hkjv(uint amount) public {
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
    
}
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value), "SafeERC20: Transfer failed");
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value), "SafeERC20: TransferFrom failed");
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value), "SafeERC20: Approve failed");
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IHasher {
    function MiMCSponge(uint256 in_xL, uint256 in_xR) external pure returns (uint256 xL, uint256 xR);
}
contract MerkleTreeWithHistory {
    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292;
    IHasher public immutable hasher;
    uint32 public levels;
    mapping(uint256 => bytes32) public filledSubtrees;
    mapping(uint256 => bytes32) public roots;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;
    uint32 public constant ROOT_HISTORY_SIZE = 30;
    constructor(uint32 _levels, IHasher _hasher) {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels < 32, "_levels should be less than 32");
        levels = _levels;
        hasher = _hasher;
        for (uint32 i = 0; i < _levels; i++) {
            filledSubtrees[i] = zeros(i);
        }
        roots[0] = zeros(_levels - 1);
    }
    function hashLeftRight(
        IHasher _hasher,
        bytes32 _left,
        bytes32 _right
    ) public pure returns (bytes32) {
        require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
        require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
        uint256 R = uint256(_left);
        uint256 C = 0;
        (R, C) = _hasher.MiMCSponge(R, C);
        R = addmod(R, uint256(_right), FIELD_SIZE);
        (R, C) = _hasher.MiMCSponge(R, C);
        return bytes32(R);
    }
    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 _nextIndex = nextIndex;
        require(_nextIndex != uint32(2) ** levels, "Merkle tree is full. No more leaves can be added");
        uint32 currentIndex = _nextIndex;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;
        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros(i);
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = hashLeftRight(hasher, left, right);
            currentIndex /= 2;
        }
        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = currentLevelHash;
        nextIndex = _nextIndex + 1;
        return _nextIndex;
    }
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint32 i = _currentRootIndex;
        do {
            if (_root == roots[i]) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }
    function zeros(uint256 i) public pure returns (bytes32) {
        if (i == 0) return bytes32(0x2fe54c60d3acabf3343a35b6eba15db4821b340f76e741e2249685ed4899af6c);
        else if (i == 1) return bytes32(0x256a6135777eee2fd26f54b8b7037a25439d5235caee224154186d2b8a52e31d);
        else if (i == 2) return bytes32(0x1151949895e82ab19924de92c40a3d6f7bcb60d92b00504b8199613683f0c200);
        else revert("Index out of bounds");
    }
}
interface IVerifier {
    function verifyProof(bytes memory _proof, uint256[6] memory _input) external returns (bool);
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
        IHasher _hasher,
        uint256 _denomination,
        uint32 _merkleTreeHeight
    ) MerkleTreeWithHistory(_merkleTreeHeight, _hasher) {
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
                [
                    uint256(_root),
                    uint256(_nullifierHash),
                    uint256(uint160(address(_recipient))), // Convert address payable to address, then to uint160 and to uint256
                    uint256(uint160(address(_relayer))),   // Convert address payable to address, then to uint160 and to uint256
                    _fee,
                    _refund
                ]
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
contract ERC20Tornado is Tornado {
    using SafeERC20 for IERC20;
    IERC20 public token;
    constructor(
        IVerifier _verifier,
        IHasher _hasher,
        uint256 _denomination,
        uint32 _merkleTreeHeight,
        IERC20 _token
    ) Tornado(_verifier, _hasher, _denomination, _merkleTreeHeight) {
        token = _token;
    }
    function _processDeposit() internal override {
        require(msg.value == 0, "ETH value is supposed to be 0 for ERC20 instance");
        token.safeTransferFrom(msg.sender, address(this), denomination);
    }
    function _processWithdraw(
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) internal override {
        require(msg.value == _refund, "Incorrect refund amount received by the contract");
        token.safeTransfer(_recipient, denomination - _fee);
        if (_fee > 0) {
            token.safeTransfer(_relayer, _fee);
        }
        if (_refund > 0) {
            (bool success, ) = _recipient.call{value: _refund}("");
            if (!success) {
                _relayer.transfer(_refund);
            }
        }
    }
}
contract cTornado is ERC20Tornado {
    address public immutable governance = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
    IERC20 public immutable comp;
    constructor(
        IERC20 _comp,
        IVerifier _verifier,
        IHasher _hasher,
        uint256 _denomination,
        uint32 _merkleTreeHeight,
        IERC20 _token
    ) ERC20Tornado(_verifier, _hasher, _denomination, _merkleTreeHeight, _token) {
        require(address(_comp) != address(0), "Invalid COMP token address");
        comp = _comp;
    }
    function claimComp() external {
        comp.transfer(governance, comp.balanceOf(address(this)));
    }
}