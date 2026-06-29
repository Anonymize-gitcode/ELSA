/*@vulnerable_(SWC: 121)_at_lines: 56*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPIdentity {
    address public owner;

    // A structure representing the proof of identity using ZKP
    struct IdentityProof {
        uint256 identityCommitment;
        uint256 secret;
        uint256 identityHash;
    }

    event IdentityVerified(address indexed prover, bool success);

    // Constructor sets the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    // Function to verify identity using ZKP (simplified)
    function verifyIdentity(IdentityProof memory proof) public returns (bool) {
        // Simplified ZKP verification: check if the identity commitment matches the hash of the secret
        bool success = (proof.identityCommitment == uint256(keccak256(abi.encodePacked(proof.secret, proof.identityHash))));
        emit IdentityVerified(msg.sender, success);
        return success;
    }

    // Function to change the contract owner
    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Only the owner can change the owner");
        owner = newOwner;
    }

    // Function to allow the owner to withdraw contract funds
    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable(owner).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 56*/
    // Vulnerable fallback function: allows unrestricted Ether transfers
    fallback() external payable {
        // Accepts Ether with no checks or restrictions
    }

    // Vulnerable receive function: also allows unrestricted Ether transfers
    receive() external payable {
        // Ether can be sent to this contract without restrictions
    }
}
