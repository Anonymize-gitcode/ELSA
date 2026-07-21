/*@vulnerable_(SWC: 110)_at_lines: 40*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAgeVerifier {
    function verifyAgeProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithAgeVerification{
    IAgeVerifier public verifier;
    mapping(address => bool) public isVerified;
    uint256 public verifiedUsers;
    uint256 public constant MAX_VERIFIED_USERS = 200;

    event AgeVerified(address indexed user);
    event VerificationFailed(address indexed user);

    constructor(address verifierAddress) {
        verifier = IAgeVerifier(verifierAddress);
        verifiedUsers = 0;
    }

    // Function to verify the ZKP proof of age and unlock features for the user
    function verifyAndUnlockFeature(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        require(!isVerified[msg.sender], "User is already verified.");

        // Verify the user's age using the ZKP verifier
        bool proofValid = verifier.verifyAgeProof(a, b, c, input);
        uint256 userAge = input[0];

        // Only verify users who are 18 or older
        require(userAge >= 18, "User must be 18 or older.");

        // Assert to limit the number of verified users
        assert(verifiedUsers < MAX_VERIFIED_USERS);

        if (proofValid) {
            isVerified[msg.sender] = true;
            verifiedUsers += 1;
            emit AgeVerified(msg.sender);
        } else {
            emit VerificationFailed(msg.sender);
        }
    }

    // Function to check if a user is verified
    function isUserVerified(address user) public view returns (bool) {
        return isVerified[user];
    }

    // Function to get the total number of verified users
    function getTotalVerifiedUsers() public view returns (uint256) {
        return verifiedUsers;
    }
}
