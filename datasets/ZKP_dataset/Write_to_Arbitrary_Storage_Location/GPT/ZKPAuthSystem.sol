/*@vulnerable_(SWC: 124)_at_lines: 60*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAuthSystem {
    struct Proof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public owner;
    mapping(address => bool) public authorizedUsers;

    event UserAuthorized(address indexed user);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Weak ZKP validation logic
    function checkProof(Proof memory proof, uint256 referenceValue) internal pure returns (bool) {
        // Vulnerability: Simplified check only validating part of the proof
        return proof.a[0] == referenceValue && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 60
    Vulnerability: The checkProof function does not implement proper cryptographic proof verification. 
    Instead, it performs simplistic value checks, allowing arbitrary proofs to be falsely validated.
    */
    function authorizeUser(Proof memory proof, uint256 referenceValue) public {
        require(checkProof(proof, referenceValue), "Proof verification failed");
        authorizedUsers[msg.sender] = true;
        emit UserAuthorized(msg.sender);
    }

    function isUserAuthorized(address user) public view returns (bool) {
        return authorizedUsers[user];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function revokeUser(address user) public onlyOwner {
        authorizedUsers[user] = false;
    }
}
