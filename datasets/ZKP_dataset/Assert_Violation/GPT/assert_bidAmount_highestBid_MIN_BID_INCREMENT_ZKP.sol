/*@vulnerable_(SWC: 110)_at_lines: 40*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuctionVerifier {
    function verifyBidProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithAuctionAndSWC110 {
    IAuctionVerifier public verifier;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public auctionEnd;
    bool public auctionEnded;
    uint256 public constant MIN_BID_INCREMENT = 100;

    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 highestBid);

    constructor(address verifierAddress, uint256 auctionDuration) {
        verifier = IAuctionVerifier(verifierAddress);
        auctionEnd = block.timestamp + auctionDuration;
        auctionEnded = false;
        highestBid = 0;
        highestBidder = address(0);
    }

    // Function to verify the ZKP proof of a bid and place a bid
    function verifyAndPlaceBid(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) public {
        require(block.timestamp < auctionEnd, "Auction already ended.");
        require(!auctionEnded, "Auction has ended.");

        // Verifies the bid using the ZKP verifier
        bool proofValid = verifier.verifyBidProof(a, b, c, input);

        uint256 bidAmount = input[0];

        // Ensures that the bid increment meets the minimum requirement
        assert(bidAmount >= highestBid + MIN_BID_INCREMENT);

        // If the proof is valid, and the bid amount is higher, update the bid
        if (proofValid && bidAmount > highestBid) {
            highestBid = bidAmount;
            highestBidder = msg.sender;
            emit BidPlaced(msg.sender, bidAmount);
        }
    }

    // Function to end the auction
    function endAuction() public {
        require(block.timestamp >= auctionEnd, "Auction is still ongoing.");
        require(!auctionEnded, "Auction already ended.");

        auctionEnded = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    // Function to get the current highest bid
    function getHighestBid() public view returns (uint256) {
        return highestBid;
    }
}
