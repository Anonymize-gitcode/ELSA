/*@vulnerable_(SWC: 124)_at_lines: 48*/
// SPDX-License-Identifier: MIT
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

    // A simplistic ZKP validation method
    function validateZKP(ZKP memory proof, uint256 publicValue) internal pure returns (bool) {
        // Flawed validation: does not properly verify the proof, just compares arbitrary values
        return proof.a[0] == publicValue && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 48
    Vulnerability: The validateZKP function does not provide proper cryptographic validation. 
    It just checks if arbitrary values match, allowing an attacker to bypass verification by submitting any valid non-zero input.
    */
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
