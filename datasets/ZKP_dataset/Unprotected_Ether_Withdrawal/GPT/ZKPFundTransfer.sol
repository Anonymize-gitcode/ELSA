/*@vulnerable_(SWC: 105)_at_lines: 58*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPFundTransfer {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit function to add ether to the user's balance
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Dummy zero-knowledge proof verifier
    // This function simulates the verification of a zero-knowledge proof
    function verifyZKP(bytes32 publicInput, bytes memory proof) public pure returns (bool) {
        // In a real ZKP setup, this would involve cryptographic checks
        return true; // Assume proof is always valid for demonstration purposes
    }

    // ZKP-based fund transfer
    // The sender must provide a valid zero-knowledge proof to transfer funds
    function transferWithZKP(
        address _recipient,
        uint256 _amount,
        bytes32 publicInput,
        bytes memory proof
    ) public {
        require(verifyZKP(publicInput, proof), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    // @vulnerable_(SWC: 105)_at_lines: 58
    // Unprotected withdrawal function
    // This function allows anyone to withdraw funds from any user's balance
    function withdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
