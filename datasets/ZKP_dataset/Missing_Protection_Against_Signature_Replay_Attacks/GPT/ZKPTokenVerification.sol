/*@vulnerable_(SWC: 121)_at_lines: 62*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPTokenVerification {
    address public owner;

    // Structure for storing ZKP-based token ownership proofs
    struct TokenProof {
        uint256 tokenId;
        uint256 secret;
        uint256 ownershipHash;
    }

    event TokenOwnershipVerified(address indexed user, uint256 tokenId, bool success);

    // Constructor sets the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    // Function to verify token ownership using ZKP (simplified)
    function verifyTokenOwnership(TokenProof memory proof) public returns (bool) {
        // Verify if the ownershipHash matches the tokenId and secret
        bool success = (proof.ownershipHash == uint256(keccak256(abi.encodePacked(proof.tokenId, proof.secret))));
        emit TokenOwnershipVerified(msg.sender, proof.tokenId, success);
        return success;
    }

    // Allows the owner to change ownership of the contract
    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Only the owner can change ownership");
        owner = newOwner;
    }

    // Allows the owner to withdraw funds from the contract
    function withdrawFunds() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable(owner).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 62*/
    // Vulnerable fallback function: allows unrestricted Ether transfers
    fallback() external payable {
        // Ether is accepted without any checks or restrictions
    }

    // Vulnerable receive function: also allows unrestricted Ether transfers
    receive() external payable {
        // Ether is accepted with no restrictions
    }
}
