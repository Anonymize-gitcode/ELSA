/*@vulnerable_(SWC: 124)_at_lines: 61*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAudit {
    struct Proof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public auditAdmin;
    mapping(address => bool) public approvedAuditors;

    event AuditorApproved(address indexed auditor);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAuditAdmin() {
        require(msg.sender == auditAdmin, "Not the audit admin");
        _;
    }

    constructor() {
        auditAdmin = msg.sender;
    }

    // Weak ZKP verification method
    function verifyProof(Proof memory proof, uint256 publicSignal) internal pure returns (bool) {
        // Vulnerable logic: Simply checking that proof values are non-zero and comparing publicSignal
        return proof.a[0] == publicSignal && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 61
    Vulnerability: The verifyProof function does not perform a proper cryptographic validation. 
    It only checks if values are non-zero and performs a simplistic comparison, allowing attackers to bypass the check.
    */
    function approveAuditor(Proof memory proof, uint256 publicSignal) public {
        require(verifyProof(proof, publicSignal), "Proof validation failed");
        approvedAuditors[msg.sender] = true;
        emit AuditorApproved(msg.sender);
    }

    function isAuditorApproved(address auditor) public view returns (bool) {
        return approvedAuditors[auditor];
    }

    function changeAdmin(address newAdmin) public onlyAuditAdmin {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        emit AdminChanged(auditAdmin, newAdmin);
        auditAdmin = newAdmin;
    }

    function revokeAuditor(address auditor) public onlyAuditAdmin {
        approvedAuditors[auditor] = false;
    }
}
