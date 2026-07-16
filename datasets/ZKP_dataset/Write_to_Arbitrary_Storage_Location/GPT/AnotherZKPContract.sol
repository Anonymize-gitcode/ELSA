/*@vulnerable_(SWC: 124)_at_lines: 40*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AnotherZKPContract {
    struct Proof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public owner;
    mapping(address => bool) public verifiedUsers;

    event VerificationSuccessful(address user);
    event OwnershipTransferred(address oldOwner, address newOwner);

    constructor() {
        owner = msg.sender;
    }

    // Dummy verifier logic simulating ZKP proof verification
    function verifyZKP(Proof memory proof, uint256 publicInput) internal pure returns (bool) {
        // Basic incorrect validation: Always returns true if proof inputs are non-zero
        return proof.a[0] == publicInput && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 40
    Vulnerability: Incorrect access control. The verify function does not properly validate the proof against public inputs, 
    leading to incorrect verification of users. Attackers can use any valid proof format, with arbitrary values, 
    to mark themselves as verified.
    */
    function verify(Proof memory proof, uint256 publicInput) public {
        require(verifyZKP(proof, publicInput), "Proof validation failed");
        verifiedUsers[msg.sender] = true;
        emit VerificationSuccessful(msg.sender);
    }

    function isVerified(address user) public view returns (bool) {
        return verifiedUsers[user];
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Not the contract owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function revokeVerification(address user) public {
        require(msg.sender == owner, "Only owner can revoke");
        verifiedUsers[user] = false;
    }
}
