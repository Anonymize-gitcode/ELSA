/*@vulnerable_(SWC: 124)_at_lines: 51*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKProofAuthorization {
    struct ZKProof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    mapping(address => bool) public approvedUsers;
    address public contractAdmin;

    event UserApproved(address indexed user);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == contractAdmin, "Only admin can execute this");
        _;
    }

    constructor() {
        contractAdmin = msg.sender;
    }

    // Insecure proof validation logic for demonstration purposes
    function verifyZKP(ZKProof memory proof) internal pure returns (bool) {
        // Vulnerable: Simplistic check that doesn't validate the ZKP correctly
        return proof.a[0] != 0 && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 51
    Vulnerability: Insufficient cryptographic validation of proof. The verifyZKP function simply checks if the proof values 
    are non-zero, making it possible for malicious users to submit any valid-looking but incorrect proofs.
    */
    function approveUser(ZKProof memory proof) public {
        require(verifyZKP(proof), "Proof verification failed");
        approvedUsers[msg.sender] = true;
        emit UserApproved(msg.sender);
    }

    function isApproved(address user) public view returns (bool) {
        return approvedUsers[user];
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be zero address");
        emit AdminTransferred(contractAdmin, newAdmin);
        contractAdmin = newAdmin;
    }

    function revokeApproval(address user) public onlyAdmin {
        approvedUsers[user] = false;
    }
}
