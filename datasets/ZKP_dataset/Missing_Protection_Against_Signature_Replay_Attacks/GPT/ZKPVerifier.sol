/*@vulnerable_(SWC: 121)_at_lines: 46*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPVerifier {
    address public owner;

    // This structure represents a ZKP proof
    struct ZKProof {
        uint256 a;
        uint256 b;
        uint256 c;
    }

    event ProofVerified(address indexed verifier, bool success);

    // Constructor sets the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    // Verify a simple ZKP, just for demonstration purposes
    function verifyProof(ZKProof memory proof) public returns (bool) {
        // Simplistic proof verification: a + b == c
        bool success = (proof.a + proof.b == proof.c);
        emit ProofVerified(msg.sender, success);
        return success;
    }

    // Function to update the owner's address
    function updateOwner(address newOwner) public {
        require(msg.sender == owner, "Only the owner can update");
        owner = newOwner;
    }

    // Allows the owner to withdraw funds from the contract
    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 46*/
    // Fallback function vulnerable due to lack of restrictions on Ether reception
    fallback() external payable {
        // Accepts Ether with no checks
    }

    // Similarly vulnerable receive function
    receive() external payable {
        // No restriction on who can send Ether
    }
}
