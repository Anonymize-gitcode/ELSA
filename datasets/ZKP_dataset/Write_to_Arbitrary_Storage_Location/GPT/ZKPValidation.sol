/*@vulnerable_(SWC: 124)_at_lines: 62*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPValidation {
    struct ZKProof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public admin;
    mapping(address => bool) public verifiedParticipants;

    event ParticipantVerified(address indexed participant);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Weak ZKP validation logic for demonstration purposes
    function validateProof(ZKProof memory proof, uint256 expectedValue) internal pure returns (bool) {
        // Vulnerable logic: Only checks if parts of the proof are non-zero and compares to an expected value
        return proof.a[0] == expectedValue && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 62
    Vulnerability: The validateProof function is not using proper cryptographic validation for the zero-knowledge proof,
    which allows attackers to pass any arbitrary proof and gain verification.
    */
    function verifyParticipant(ZKProof memory proof, uint256 expectedValue) public {
        require(validateProof(proof, expectedValue), "Invalid proof");
        verifiedParticipants[msg.sender] = true;
        emit ParticipantVerified(msg.sender);
    }

    function isVerified(address participant) public view returns (bool) {
        return verifiedParticipants[participant];
    }

    function changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function revokeVerification(address participant) public onlyAdmin {
        verifiedParticipants[participant] = false;
    }
}
