/*@vulnerable_(SWC: 105)_at_lines: 76*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPChallenge {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether to the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // A simple ZKP verification simulation
    // In real-world usage, this function would verify cryptographic proofs
    function verifyZKP(uint256 inputHash, uint256 proof) public pure returns (bool) {
        // A basic comparison for demonstration purposes
        return uint256(keccak256(abi.encodePacked(inputHash))) == proof;
    }

    // Zero-knowledge proof based fund release function
    // Allows users to transfer Ether if they can provide a valid ZKP
    function releaseFundsWithZKP(
        uint256 _amount, 
        uint256 inputHash, 
        uint256 proof
    ) public {
        require(verifyZKP(inputHash, proof), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // @vulnerable_(SWC: 105)_at_lines: 76
    // Unprotected Ether withdrawal
    // This function allows anyone to withdraw funds from another user's balance,
    // introducing a SWC-105 vulnerability by not requiring permissions or checks
    function unsafeWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
