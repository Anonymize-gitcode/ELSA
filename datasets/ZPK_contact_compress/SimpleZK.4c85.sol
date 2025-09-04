pragma solidity ^0.8.0;
contract SimpleZKP {
    struct ZKP {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }
    address public owner;
    mapping(address => bool) public authorizedUsers;
    event UserAuthorized(address user);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }
    function validateZKP(ZKP memory proof, uint256 publicValue) internal pure returns (bool) {
        return proof.a[0] == publicValue && proof.b[0] != 0 && proof.c[0] != 0;
    }
    
    function authorizeUser(ZKP memory proof, uint256 publicValue) public {
        require(validateZKP(proof, publicValue), "Invalid ZKP");
        authorizedUsers[msg.sender] = true;
        emit UserAuthorized(msg.sender);
    }
    function isAuthorized(address user) public view returns (bool) {
        return authorizedUsers[user];
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function revokeAuthorization(address user) public onlyOwner {
        authorizedUsers[user] = false;
    }
}