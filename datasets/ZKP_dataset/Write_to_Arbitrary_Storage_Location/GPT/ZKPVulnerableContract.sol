/*@vulnerable_(SWC: 124)_at_lines: 37*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPVulnerableContract {
    struct Proof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public owner;
    mapping(address => bool) public verifiedUsers;

    event Verified(address user);

    constructor() {
        owner = msg.sender;
    }

    // Fake ZKP verifier for demonstration purposes.
    // In a real ZKP, this function would use cryptographic proof validation.
    function verifyProof(Proof memory proof) internal pure returns (bool) {
        // Simple, insecure placeholder logic that accepts any proof
        return proof.a[0] != 0 && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 37
    Vulnerability: Insufficient validation of cryptographic proof.
    The verifyProof function just checks for non-zero values rather than validating 
    the proof against a verifier key, allowing anyone to submit a fake proof.
    */
    function verify(Proof memory proof) public {
        require(verifyProof(proof), "Invalid ZKP proof");
        verifiedUsers[msg.sender] = true;
        emit Verified(msg.sender);
    }

    function isVerified(address user) public view returns (bool) {
        return verifiedUsers[user];
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only the owner can transfer ownership");
        owner = newOwner;
    }
}
