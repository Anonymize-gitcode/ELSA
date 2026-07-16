/*@vulnerable_(SWC: 110)_at_lines: 39*/
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
    mapping(address => bool) public verifiedUsers;
    uint256 public verifiedCount;
    uint256 public constant MAX_VERIFIED_USERS = 100;

    event UserVerified(address indexed user, bool success);

    constructor(address verifierAddress) {
        verifier = IAgeVerifier(verifierAddress);
        verifiedCount = 0;
    }

    // Function to verify the ZKP proof of user's age and update the verified status
    function verifyUserAge(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        require(!verifiedUsers[msg.sender], "User is already verified.");
        
        // Verify the user's age using the ZKP verifier
        bool proofValid = verifier.verifyAgeProof(a, b, c, input);

        uint256 userAge = input[0];

        // Only verify users who are 18 or older
        require(userAge >= 18, "User must be 18 or older to get verified.");

        // Restriction on the number of verified users
        assert(verifiedCount < MAX_VERIFIED_USERS);

        if (proofValid) {
            verifiedUsers[msg.sender] = true;
            verifiedCount += 1;
            emit UserVerified(msg.sender, true);
        } else {
            emit UserVerified(msg.sender, false);
        }
    }

    // Function to check if a user is verified
    function isUserVerified(address user) public view returns (bool) {
        return verifiedUsers[user];
    }
}
