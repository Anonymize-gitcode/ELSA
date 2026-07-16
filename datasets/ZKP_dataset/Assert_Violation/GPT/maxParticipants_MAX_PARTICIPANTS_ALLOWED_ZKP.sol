/*@vulnerable_(SWC: 110)_at_lines: 45*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILotteryVerifier {
    function verifyEligibilityProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithLottery{
    ILotteryVerifier public verifier;
    mapping(address => bool) public hasEntered;
    address[] public participants;
    uint256 public maxParticipants;
    uint256 public constant MAX_PARTICIPANTS_ALLOWED = 50;

    event ParticipantAdded(address indexed participant);
    event LotteryClosed(address winner);

    constructor(address verifierAddress) {
        verifier = ILotteryVerifier(verifierAddress);
        maxParticipants = 0;
    }

    // Function to verify ZKP proof of eligibility and add the participant to the lottery
    function verifyAndEnterLottery(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        require(!hasEntered[msg.sender], "You have already entered the lottery.");

        // Verify the user's eligibility to participate in the lottery using ZKP
        bool proofValid = verifier.verifyEligibilityProof(a, b, c, input);

        // Only allow participants with proof of eligibility
        require(proofValid, "Invalid eligibility proof.");

        // Assert the maximum number of participants is not exceeded
        assert(maxParticipants < MAX_PARTICIPANTS_ALLOWED);

        // If proof is valid and participants are below the limit, add the participant
        hasEntered[msg.sender] = true;
        participants.push(msg.sender);
        maxParticipants += 1;

        emit ParticipantAdded(msg.sender);
    }

    // Function to randomly select a winner (simplified version)
    function closeLotteryAndSelectWinner() public {
        require(participants.length > 0, "No participants in the lottery.");
        require(maxParticipants > 0, "Lottery hasn't started.");

        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp))) % participants.length;
        address winner = participants[winnerIndex];

        emit LotteryClosed(winner);
    }

    // Function to check the total number of participants
    function getParticipantCount() public view returns (uint256) {
        return participants.length;
    }
}
