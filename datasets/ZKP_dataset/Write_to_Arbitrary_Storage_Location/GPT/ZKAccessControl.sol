/*@vulnerable_(SWC: 124)_at_lines: 59*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKAccessControl {
    struct Proof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public contractOwner;
    mapping(address => bool) public hasAccess;

    event AccessGranted(address indexed user);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Caller is not the owner");
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    // Faulty ZKP validation function
    function validateZKP(Proof memory proof, uint256 input) internal pure returns (bool) {
        // Vulnerability: Simplistic validation logic that only checks if values are non-zero and loosely compares inputs
        return proof.a[0] == input && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 59
    Vulnerability: The validateZKP function does not perform full cryptographic validation of the zero-knowledge proof. 
    It only checks a simple condition, allowing attackers to bypass security checks with arbitrary inputs.
    */
    function grantAccess(Proof memory proof, uint256 input) public {
        require(validateZKP(proof, input), "Invalid ZKP");
        hasAccess[msg.sender] = true;
        emit AccessGranted(msg.sender);
    }

    function checkAccess(address user) public view returns (bool) {
        return hasAccess[user];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        emit OwnershipTransferred(contractOwner, newOwner);
        contractOwner = newOwner;
    }

    function revokeAccess(address user) public onlyOwner {
        hasAccess[user] = false;
    }
}
