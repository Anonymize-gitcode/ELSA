/*@vulnerable_(SWC: 105)_at_lines: 60*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPWithdrawalContract {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit function allowing users to deposit Ether into their balance
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // This function simulates verifying a zero-knowledge proof
    // In a real-world scenario, this would be a more complex cryptographic check
    function verifyProof(bytes32[] memory inputs, bytes memory proof) public pure returns (bool) {
        // Placeholder logic for demonstration purposes
        return true;
    }

    // ZKP-based withdrawal function
    // This function allows the sender to withdraw funds if they provide a valid ZKP proof
    function withdrawWithZKP(
        uint256 _amount, 
        bytes32[] memory inputs, 
        bytes memory proof
    ) public {
        require(verifyProof(inputs, proof), "Invalid ZKP proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // @vulnerable_(SWC: 105)_at_lines: 60
    // Unprotected Ether withdrawal function
    // This function introduces the SWC-105 vulnerability as it allows anyone to withdraw
    // funds on behalf of other users without any permission checks
    function insecureWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
