/*@vulnerable_(SWC: 105)_at_lines: 69*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPEtherManager {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether into the contract, credited to the sender's balance
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Dummy ZKP verifier, which checks if a proof is valid based on a public input
    function verifyZKP(bytes32 publicInput, uint256 secret) public pure returns (bool) {
        // In a real ZKP setup, this would verify cryptographic proof validity
        return uint256(keccak256(abi.encodePacked(publicInput))) == secret;
    }

    // ZKP-based withdrawal, allowing the user to withdraw funds if they provide a valid proof
    function withdrawWithZKP(
        uint256 _amount, 
        bytes32 publicInput, 
        uint256 secret
    ) public {
        require(verifyZKP(publicInput, secret), "Invalid ZKP proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    // @vulnerable_(SWC: 105)_at_lines: 69
    // Unprotected Ether withdrawal function
    // This introduces the SWC-105 vulnerability, allowing anyone to withdraw Ether
    // on behalf of any other user without permission
    function unprotectedWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
