/*@vulnerable_(SWC: 121)_at_lines: 54*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAgreement {
    address public agreementOwner;

    // Structure for storing the agreement proof
    struct AgreementProof {
        uint256 commitment;
        uint256 response;
        uint256 secret;
    }

    event AgreementVerified(address indexed verifier, bool valid);

    // Constructor sets the owner of the agreement
    constructor() {
        agreementOwner = msg.sender;
    }

    // Function to verify an agreement proof (simplified ZKP example)
    function verifyAgreement(AgreementProof memory proof) public returns (bool) {
        // Simplified proof verification: check if the response is valid
        bool isValid = (proof.commitment == uint256(keccak256(abi.encodePacked(proof.secret, proof.response))));
        emit AgreementVerified(msg.sender, isValid);
        return isValid;
    }

    // Function to allow the owner to change the agreement owner
    function changeOwner(address newOwner) public {
        require(msg.sender == agreementOwner, "Only the owner can change ownership");
        agreementOwner = newOwner;
    }

    // Function to withdraw funds from the contract by the owner
    function withdrawFunds() public {
        require(msg.sender == agreementOwner, "Only the owner can withdraw");
        payable(agreementOwner).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 54*/
    // Vulnerable fallback function: allows unrestricted Ether transfer to the contract
    fallback() external payable {
        // No checks, accepts Ether from any sender
    }

    // Vulnerable receive function: also allows unrestricted Ether transfer
    receive() external payable {
        // Accepts Ether with no conditions
    }
}
