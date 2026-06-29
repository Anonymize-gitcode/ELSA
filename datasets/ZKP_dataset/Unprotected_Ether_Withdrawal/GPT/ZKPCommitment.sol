/*@vulnerable_(SWC: 105)_at_lines: 79*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPCommitment {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether into the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Simulate a ZKP verification process using commitment schemes
    function verifyCommitment(bytes32 commitment, uint256 secret) public pure returns (bool) {
        // In a real-world scenario, this would verify a commitment using ZKP techniques
        return keccak256(abi.encodePacked(secret)) == commitment;
    }

    // ZKP-based withdrawal
    // The user must provide a valid zero-knowledge proof in the form of a secret that matches the commitment
    function withdrawWithZKP(
        uint256 _amount, 
        bytes32 commitment, 
        uint256 secret
    ) public {
        require(verifyCommitment(commitment, secret), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // @vulnerable_(SWC: 105)_at_lines: 79
    // Unprotected Ether withdrawal
    // This function allows anyone to withdraw funds from any user's account without restriction,
    // creating a SWC-105 vulnerability
    function insecureWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // Fallback function to allow the contract to receive Ether
    receive() external payable {}
}
