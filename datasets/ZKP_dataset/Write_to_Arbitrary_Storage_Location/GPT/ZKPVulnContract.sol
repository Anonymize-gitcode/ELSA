/*@vulnerable_(SWC: 124)_at_lines: 41*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPVulnContract {
    struct Proof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public owner;
    mapping(address => bool) public verifiedUsers;

    event VerificationCompleted(address user);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Insecure ZKP verifier (for demonstration purposes)
    function validateProof(Proof memory proof) internal pure returns (bool) {
        // The logic here only checks if values are non-zero instead of doing real ZKP verification
        return proof.a[0] != 0 && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 41
    Vulnerability: Inadequate cryptographic validation of proofs. The validateProof function only checks if the values 
    in the proof are non-zero, allowing any attacker to submit arbitrary data and bypass the intended security.
    */
    function verify(Proof memory proof) public {
        // Simulate ZKP validation (insecure)
        require(validateProof(proof), "Proof verification failed");
        verifiedUsers[msg.sender] = true;
        emit VerificationCompleted(msg.sender);
    }

    function isVerified(address user) public view returns (bool) {
        return verifiedUsers[user];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function revokeVerification(address user) public onlyOwner {
        verifiedUsers[user] = false;
    }
}
