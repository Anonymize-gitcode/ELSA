/*@vulnerable_(SWC: 110)_at_lines: 36*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDonationVerifier {
    function verifyDonationProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithDonation{
    IDonationVerifier public verifier;
    mapping(address => uint256) public donations;
    uint256 public totalDonations;
    uint256 public constant MAX_DONATION = 5000;

    event DonationReceived(address indexed donor, uint256 amount);

    constructor(address verifierAddress) {
        verifier = IDonationVerifier(verifierAddress);
        totalDonations = 0;
    }

    // Function to verify the ZKP donation proof and accept the donation
    function verifyAndDonate(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public payable {
        require(msg.value == input[0], "Donation amount must match the proof input.");

        // Verify the donation using the ZKP verifier
        bool proofValid = verifier.verifyDonationProof(a, b, c, input);

        uint256 donationAmount = input[0];

        // Ensure total donations do not exceed the defined maximum limit
        assert(totalDonations + donationAmount <= MAX_DONATION);

        // If the proof is valid, accept the donation and update state
        if (proofValid) {
            donations[msg.sender] += donationAmount;
            totalDonations += donationAmount;
            emit DonationReceived(msg.sender, donationAmount);
        }
    }

    // Function to check the donation amount of a specific donor
    function getDonationAmount(address donor) public view returns (uint256) {
        return donations[donor];
    }

    // Function to withdraw the donations (only by the contract owner, for simplicity)
    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}
