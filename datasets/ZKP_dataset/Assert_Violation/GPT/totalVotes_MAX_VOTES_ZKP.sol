/*@vulnerable_(SWC: 110)_at_lines: 37*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVoteVerifier {
    function verifyVoteProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithVotingAndSWC110 {
    IVoteVerifier public verifier;
    mapping(address => bool) public hasVoted;
    mapping(uint256 => uint256) public candidateVotes;
    uint256 public totalVotes;
    uint256 public constant MAX_VOTES = 500;

    event VoteCast(address indexed voter, uint256 candidate);
    event VoteVerificationFailed(address indexed voter);

    constructor(address verifierAddress) {
        verifier = IVoteVerifier(verifierAddress);
        totalVotes = 0;
    }

    // Function to verify the ZKP vote proof and cast the vote
    function verifyAndCastVote(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        require(!hasVoted[msg.sender], "You have already voted.");

        // Verify the user's vote using the ZKP verifier
        bool proofValid = verifier.verifyVoteProof(a, b, c, input);
        uint256 candidate = input[0];  // Assume input contains candidate ID

        // Ensures total votes do not exceed the maximum allowed limit
        assert(totalVotes < MAX_VOTES);  

        if (proofValid) {
            hasVoted[msg.sender] = true;
            candidateVotes[candidate] += 1;
            totalVotes += 1;
            emit VoteCast(msg.sender, candidate);
        } else {
            emit VoteVerificationFailed(msg.sender);
        }
    }

    // Function to get the total votes for a candidate
    function getVotesForCandidate(uint256 candidate) public view returns (uint256) {
        return candidateVotes[candidate];
    }

    // Function to get the total number of votes cast
    function getTotalVotes() public view returns (uint256) {
        return totalVotes;
    }
}
