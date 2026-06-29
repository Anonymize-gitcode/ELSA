/*@vulnerable_(SWC: 110)_at_lines: 36*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardVerifier {
    function verifyRewardProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithRewardSystemAndSWC110 {
    IRewardVerifier public verifier;
    mapping(address => uint256) public userPoints;
    uint256 public totalPointsDistributed;
    uint256 public constant MAX_POINTS = 10000;

    event PointsAwarded(address indexed user, uint256 points);
    event VerificationFailed(address indexed user);

    constructor(address verifierAddress) {
        verifier = IRewardVerifier(verifierAddress);
        totalPointsDistributed = 0;
    }

    // Function to verify the ZKP proof and award points to the user
    function verifyAndAwardPoints(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        uint256 pointsToAward = input[0];

        // Verify the user's eligibility for rewards using ZKP
        bool proofValid = verifier.verifyRewardProof(a, b, c, input);

        // Check the total points limit before awarding points
        assert(totalPointsDistributed + pointsToAward <= MAX_POINTS);

        if (proofValid) {
            userPoints[msg.sender] += pointsToAward;
            totalPointsDistributed += pointsToAward;
            emit PointsAwarded(msg.sender, pointsToAward);
        } else {
            emit VerificationFailed(msg.sender);
        }
    }

    // Function to get the points of a user
    function getUserPoints(address user) public view returns (uint256) {
        return userPoints[user];
    }

    // Function to get the total points distributed
    function getTotalPointsDistributed() public view returns (uint256) {
        return totalPointsDistributed;
    }
}
