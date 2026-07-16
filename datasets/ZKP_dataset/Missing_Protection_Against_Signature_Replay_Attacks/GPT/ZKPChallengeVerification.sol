/*@vulnerable_(SWC: 121)_at_lines: 64*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPChallengeVerification {
    address public challengeAdmin;

    // Structure for ZKP-based challenge proof
    struct ChallengeProof {
        uint256 challengeId;
        uint256 secret;
        uint256 challengeHash;
    }

    event ChallengeVerified(address indexed challenger, uint256 challengeId, bool success);

    // Constructor sets the contract deployer as the challenge admin
    constructor() {
        challengeAdmin = msg.sender;
    }

    // Function to verify a ZKP-based challenge (simplified example)
    function verifyChallenge(ChallengeProof memory proof) public returns (bool) {
        // Simple ZKP verification: check if the challengeHash matches the challengeId and secret
        bool success = (proof.challengeHash == uint256(keccak256(abi.encodePacked(proof.challengeId, proof.secret))));
        emit ChallengeVerified(msg.sender, proof.challengeId, success);
        return success;
    }

    // Allows the challenge admin to change the admin address
    function changeAdmin(address newAdmin) public {
        require(msg.sender == challengeAdmin, "Only the challenge admin can change admin");
        challengeAdmin = newAdmin;
    }

    // Allows the challenge admin to withdraw contract funds
    function withdrawFunds() public {
        require(msg.sender == challengeAdmin, "Only the challenge admin can withdraw funds");
        payable(challengeAdmin).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 64*/
    // Vulnerable fallback function that allows unrestricted Ether transfers
    fallback() external payable {
        // Accepts Ether without any checks or restrictions
    }

    // Vulnerable receive function that also allows unrestricted Ether transfers
    receive() external payable {
        // Ether can be sent without any restrictions
    }
}
