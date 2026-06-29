/*@vulnerable_(SWC: 121)_at_lines: 50*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAudit {
    address public auditor;

    // Simple structure for zero-knowledge proof
    struct ZKP {
        uint256 input;
        uint256 output;
        uint256 secret;
    }

    event ProofAudited(address indexed auditor, bool success);

    // Constructor sets the auditor to the contract deployer
    constructor() {
        auditor = msg.sender;
    }

    // Function to audit a ZKP proof (simplified for demonstration)
    function auditProof(ZKP memory proof) public returns (bool) {
        // A simple zero-knowledge proof check
        bool isVerified = (proof.input * proof.secret == proof.output);
        emit ProofAudited(msg.sender, isVerified);
        return isVerified;
    }

    // Allows the auditor to update the auditor address
    function updateAuditor(address newAuditor) public {
        require(msg.sender == auditor, "Only the auditor can update");
        auditor = newAuditor;
    }

    // Auditor can withdraw Ether from the contract
    function withdrawEther() public {
        require(msg.sender == auditor, "Only the auditor can withdraw");
        payable(auditor).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 50*/
    // Vulnerable fallback function: no restrictions on receiving Ether
    fallback() external payable {
        // Accepts Ether with no checks or restrictions
    }

    // Vulnerable receive function
    receive() external payable {
        // Ether is accepted unconditionally
    }
}
