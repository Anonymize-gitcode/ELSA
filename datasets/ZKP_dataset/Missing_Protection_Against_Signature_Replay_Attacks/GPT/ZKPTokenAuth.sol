/*@vulnerable_(SWC: 121)_at_lines: 57*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPTokenAuth {
    address public admin;

    // Structure representing a zero-knowledge proof of token ownership
    struct TokenProof {
        uint256 tokenId;
        uint256 secret;
        uint256 tokenHash;
    }

    event TokenVerified(address indexed prover, uint256 tokenId, bool success);

    // Constructor sets the admin of the contract
    constructor() {
        admin = msg.sender;
    }

    // Function to verify a token ownership proof using ZKP (simplified)
    function verifyToken(TokenProof memory proof) public returns (bool) {
        // Simplified ZKP check: verify if tokenHash is a hash of tokenId and secret
        bool success = (proof.tokenHash == uint256(keccak256(abi.encodePacked(proof.tokenId, proof.secret))));
        emit TokenVerified(msg.sender, proof.tokenId, success);
        return success;
    }

    // Function to allow admin to change ownership of the contract
    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin, "Only the admin can change ownership");
        admin = newAdmin;
    }

    // Admin can withdraw Ether from the contract
    function withdrawFunds() public {
        require(msg.sender == admin, "Only the admin can withdraw funds");
        payable(admin).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 57*/
    // Vulnerable fallback function that accepts Ether without restrictions
    fallback() external payable {
        // No checks, Ether is accepted from any sender
    }

    // Vulnerable receive function
    receive() external payable {
        // No restrictions on who can send Ether
    }
}
