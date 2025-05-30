pragma solidity ^0.8.0;
contract ZKPAudit {
    address public auditor;
    struct ZKP {
        uint256 input;
        uint256 output;
        uint256 secret;
    }
    event ProofAudited(address indexed auditor, bool success);
    constructor() {
        auditor = msg.sender;
    }
    function auditProof(ZKP memory proof) public returns (bool) {
        bool isVerified = (proof.input * proof.secret == proof.output);
        emit ProofAudited(msg.sender, isVerified);
        return isVerified;
    }
    function updateAuditor(address newAuditor) public {
        require(msg.sender == auditor, "Only the auditor can update");
        auditor = newAuditor;
    }
    function withdrawEther() public {
        require(msg.sender == auditor, "Only the auditor can withdraw");
        payable(auditor).transfer(address(this).balance);
    }
    
    fallback() external payable {
    }
    receive() external payable {
    }
}