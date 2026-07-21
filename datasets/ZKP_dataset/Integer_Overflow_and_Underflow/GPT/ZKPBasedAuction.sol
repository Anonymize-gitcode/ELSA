/*@vulnerable_(SWC: 101)_at_lines: 36*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPBasedAuction {
    struct Bid {
        address bidder;
        uint256 amount;
    }

    address public owner;
    Bid public highestBid;
    bool public auctionEnded;

    mapping(address => bool) public hasBid;

    constructor() {
        owner = msg.sender;
        auctionEnded = false;
    }

    // Function to place a bid using a zero-knowledge proof
    function placeBid(uint256[2] memory proof, uint256[2] memory input) public payable {
        require(!auctionEnded, "Auction has already ended");
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(msg.value > highestBid.amount, "Bid amount is too low");

        if (highestBid.amount > 0) {
            // Refund the previous highest bidder
            payable(highestBid.bidder).transfer(highestBid.amount);
        }

        highestBid = Bid(msg.sender, msg.value);
        hasBid[msg.sender] = true;
    }

    // Simple mock verification function for ZKP
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Mock logic to simulate ZKP verification
        return (proof[0] ^ proof[1]) == (input[0] ^ input[1]);
    }

    // Function to withdraw funds for the highest bidder after the auction ends, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 36*/
    function withdrawFunds(uint256 amount) public {
        require(auctionEnded, "Auction is still ongoing");
        require(msg.sender == highestBid.bidder, "Only the highest bidder can withdraw");
        require(amount <= address(this).balance, "Insufficient balance in the contract");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // Updating state after the external call, which is vulnerable to reentrancy attacks
        hasBid[msg.sender] = false;
    }

    // Function to end the auction
    function endAuction() public {
        require(msg.sender == owner, "Only the owner can end the auction");
        auctionEnded = true;
    }

    // Allow the contract to receive Ether
    receive() external payable {}
}
