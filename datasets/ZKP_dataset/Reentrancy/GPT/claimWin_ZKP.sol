/*@vulnerable_(SWC: 107)_at_lines: 42*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPAuction {
    IVerifier public verifier;
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids; // Tracks the bid amount for each user

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        highestBid = 1 ether; // Initial bid set to 1 ETH
    }

    // Function to place a bid, users must provide a valid ZKP
    function placeBid(uint256 bidAmount, bytes memory proof, uint256[2] memory input) public payable {
        require(msg.value == bidAmount, "Sent value must match bid amount");
        require(bidAmount > highestBid, "Bid must be higher than the current highest bid");

        // Verifies the user's bid qualification using ZKP
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // Refunds the previous highest bidder, if applicable
        if (highestBidder != address(0)) {
            (bool success, ) = highestBidder.call{value: highestBid}("");
            require(success, "Refund failed");
        }

        // Updates the highest bid and bidder information
        highestBid = bidAmount;
        highestBidder = msg.sender;

        // Records the user's bid
        bids[msg.sender] += bidAmount;
    }

    // Function for the auction winner to claim the funds
    function claimWin(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(msg.sender == highestBidder, "Only the highest bidder can claim");

        // Verifies the claim qualification using ZKP
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // Transfer the claimed funds
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Updates the user's bid record to prevent multiple claims
        bids[msg.sender] -= amount;
    }
}
