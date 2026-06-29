/*@vulnerable_(SWC: 124)_at_lines: 57*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZeroKnowledgeProofAuth {
    struct ZKProof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public administrator;
    mapping(address => bool) public isAuthenticated;

    event UserAuthenticated(address indexed user);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == administrator, "Only admin can execute this");
        _;
    }

    constructor() {
        administrator = msg.sender;
    }

    // Fake ZKP verifier that lacks proper cryptographic checks
    function validateZKP(ZKProof memory proof, uint256 publicInput) internal pure returns (bool) {
        // Vulnerable check: It simply checks if part of the proof matches public input
        return proof.a[0] == publicInput && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 57
    Vulnerability: The validateZKP function only performs a simplistic comparison between proof values and public input,
    which allows anyone with arbitrary input to pass the verification and be authenticated.
    */
    function authenticateUser(ZKProof memory proof, uint256 publicInput) public {
        require(validateZKP(proof, publicInput), "Invalid ZKP");
        isAuthenticated[msg.sender] = true;
        emit UserAuthenticated(msg.sender);
    }

    function checkAuthentication(address user) public view returns (bool) {
        return isAuthenticated[user];
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin address cannot be zero");
        emit AdminTransferred(administrator, newAdmin);
        administrator = newAdmin;
    }

    function revokeAuthentication(address user) public onlyAdmin {
        isAuthenticated[user] = false;
    }
}
