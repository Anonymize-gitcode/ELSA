pragma solidity ^0.8.0;
contract ZKPermissions {
    struct Proof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }
    address public owner;
    mapping(address => bool) public grantedPermissions;
    event PermissionGranted(address indexed user);
    event OwnerTransferred(address indexed oldOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
    function verifyProof(Proof memory proof, uint256 challenge) internal pure returns (bool) {
        return proof.a[0] == challenge && proof.b[1] != 0 && proof.c[1] != 0;
    }
    
    function grantPermission(Proof memory proof, uint256 challenge) public {
        require(verifyProof(proof, challenge), "Invalid proof");
        grantedPermissions[msg.sender] = true;
        emit PermissionGranted(msg.sender);
    }
    function hasPermission(address user) public view returns (bool) {
        return grantedPermissions[user];
    }
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnerTransferred(owner, newOwner);
        owner = newOwner;
    }
    function revokePermission(address user) public onlyOwner {
        grantedPermissions[user] = false;
    }
}