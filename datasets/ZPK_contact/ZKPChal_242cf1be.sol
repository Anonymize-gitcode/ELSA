pragma solidity ^0.8.0;
contract ZKPChallengeVerification {
    address public challengeAdmin;
    struct ChallengeProof {
        uint256 challengeId;
        uint256 secret;
        uint256 challengeHash;
    }
    event ChallengeVerified(address indexed challenger, uint256 challengeId, bool success);
    constructor() {
        challengeAdmin = msg.sender;
    }
    function verifyChallenge(ChallengeProof memory proof) public returns (bool) {
        bool success = (proof.challengeHash == uint256(keccak256(abi.encodePacked(proof.challengeId, proof.secret))));
        emit ChallengeVerified(msg.sender, proof.challengeId, success);
        return success;
    }
    function changeAdmin(address newAdmin) public {
        require(msg.sender == challengeAdmin, "Only the challenge admin can change admin");
        challengeAdmin = newAdmin;
    }
    function withdrawFunds() public {
        require(msg.sender == challengeAdmin, "Only the challenge admin can withdraw funds");
        payable(challengeAdmin).transfer(address(this).balance);
    }
    
    fallback() external payable {
    }
    receive() external payable {
    }
}