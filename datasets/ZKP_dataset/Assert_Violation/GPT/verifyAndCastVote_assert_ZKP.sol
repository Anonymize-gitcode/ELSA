/*@vulnerable_(SWC: 110)_at_lines: 33*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZKPVerifier {
    function verifyVoteProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithVoting{
    IZKPVerifier public verifier;
    mapping(address => bool) public hasVoted;
    uint256 public voteCount;
    uint256 public constant MAX_VOTES = 100;

    event VoteCasted(address indexed voter, bool success);

    constructor(address verifierAddress) {
        verifier = IZKPVerifier(verifierAddress);
        voteCount = 0;
    }

    // Function to verify the ZKP proof of a vote and register the vote
    function verifyAndCastVote(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        // Ensure the user hasn't already voted
        require(!hasVoted[msg.sender], "You have already voted.");

        // Verify the vote using the ZKP verifier
        bool proofValid = verifier.verifyVoteProof(a, b, c, input);

        // If the proof is valid, register the vote
        if (proofValid) {
            hasVoted[msg.sender] = true;
            voteCount += 1;
        }

        // Ensure that the vote count does not exceed the maximum allowed votes
        assert(voteCount <= MAX_VOTES);

        emit VoteCasted(msg.sender, proofValid);
    }

    // Function to check if a specific user has voted
    function hasUserVoted(address voter) public view returns (bool) {
        return hasVoted[voter];
    }
}
