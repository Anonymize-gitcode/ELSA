/*@vulnerable_(SWC: 121)_at_lines: 52*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPChallenge {
    address public challengeOwner;

    // Zero-Knowledge Proof structure for a challenge
    struct ChallengeProof {
        uint256 challengeHash;
        uint256 solution;
        uint256 nonce;
    }

    event ChallengeSolved(address solver, bool success);

    // Constructor sets the contract deployer as the challenge owner
    constructor() {
        challengeOwner = msg.sender;
    }

    // Function to solve the ZKP-based challenge (simplified)
    function solveChallenge(ChallengeProof memory proof) public returns (bool) {
        // Simple ZKP verification logic (this is a mockup example)
        bool isSolved = (uint256(keccak256(abi.encodePacked(proof.solution, proof.nonce))) == proof.challengeHash);
        emit ChallengeSolved(msg.sender, isSolved);
        return isSolved;
    }

    // Allow the challenge owner to change ownership
    function changeOwner(address newOwner) public {
        require(msg.sender == challengeOwner, "Only the owner can change ownership");
        challengeOwner = newOwner;
    }

    // Allow the owner to withdraw funds from the contract
    function withdrawFunds() public {
        require(msg.sender == challengeOwner, "Only the owner can withdraw funds");
        payable(challengeOwner).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 52*/
    // Fallback function with SWC-121 vulnerability
    fallback() external payable {
        // Accept Ether without any restrictions or validations
    }

    // Vulnerable receive function
    receive() external payable {
        // Accept Ether without any checks
    }
}
