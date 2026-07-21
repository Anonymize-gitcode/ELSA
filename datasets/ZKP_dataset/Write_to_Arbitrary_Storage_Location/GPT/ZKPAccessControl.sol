/*@vulnerable_(SWC: 124)_at_lines: 54*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAccessControl {
    struct ZKProof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public owner;
    mapping(address => bool) public hasAccess;

    event AccessGranted(address indexed user);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Fake ZKP verification function for demonstration purposes
    function validateProof(ZKProof memory proof, uint256 expectedInput) internal pure returns (bool) {
        // Vulnerable check: proof is considered valid if a part of the proof matches expectedInput
        return proof.a[0] == expectedInput && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 54
    Vulnerability: The validateProof function uses an insufficient validation mechanism. It checks only partial proof values
    and doesn't perform proper ZKP validation, allowing malicious users to submit arbitrary proofs and gain access.
    */
    function grantAccess(ZKProof memory proof, uint256 expectedInput) public {
        require(validateProof(proof, expectedInput), "Invalid proof");
        hasAccess[msg.sender] = true;
        emit AccessGranted(msg.sender);
    }

    function checkAccess(address user) public view returns (bool) {
        return hasAccess[user];
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function revokeAccess(address user) public onlyOwner {
        hasAccess[user] = false;
    }
}
