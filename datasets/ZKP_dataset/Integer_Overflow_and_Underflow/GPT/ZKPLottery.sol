/*@vulnerable_(SWC: 101)_at_lines: 41*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPLottery {
    address public owner;
    uint256 public lotteryPool;
    mapping(address => uint256) public tickets;
    mapping(address => bool) public proofSubmitted;

    constructor() {
        owner = msg.sender;
    }

    // Function to submit a zero-knowledge proof for lottery participation
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");

        // Mark proof as submitted
        proofSubmitted[msg.sender] = true;
    }

    // Simple mock ZKP verification function
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // Simulated verification logic for demonstration purposes
        return (proof[0] ^ proof[1]) == (input[0] ^ input[1]);
    }

    // Function to purchase lottery tickets after proof submission
    function buyTickets(uint256 numberOfTickets) public payable {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(msg.value >= numberOfTickets * 1 ether, "Insufficient Ether to buy tickets");

        tickets[msg.sender] += numberOfTickets;
        lotteryPool += msg.value;
    }

    // Function to claim the lottery prize, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 41*/
    function claimPrize(uint256 prizeAmount) public {
        require(tickets[msg.sender] > 0, "No tickets purchased");
        require(prizeAmount <= lotteryPool, "Insufficient funds in lottery pool");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: prizeAmount}("");
        require(success, "Prize claim failed");

        // Update state after external call, leaving it vulnerable to reentrancy attacks
        tickets[msg.sender] = 0;
        lotteryPool -= prizeAmount;
    }

    // Function to view the number of tickets a user has purchased
    function getTicketCount(address participant) public view returns (uint256) {
        return tickets[participant];
    }

    // Allow the contract to receive Ether for the lottery pool
    receive() external payable {}
}
