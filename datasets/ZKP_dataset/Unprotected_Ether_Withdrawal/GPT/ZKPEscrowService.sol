/*@vulnerable_(SWC: 105)_at_lines: 94*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPEscrowService {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit function to allow users to deposit Ether into the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Simulated ZKP validation using a public input and a proof
    function validateZKP(bytes32 publicInput, bytes32 proof) public pure returns (bool) {
        // Simplified ZKP verification: compares the public input with the proof hash
        return keccak256(abi.encodePacked(publicInput)) == proof;
    }

    // ZKP-based withdrawal function where the user must provide a valid proof
    function withdrawWithZKP(
        address payable _recipient, 
        uint256 _amount, 
        bytes32 publicInput, 
        bytes32 proof
    ) public {
        require(validateZKP(publicInput, proof), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // @vulnerable_(SWC: 105)_at_lines: 94
    // Unprotected Ether withdrawal
    // This introduces SWC-105 vulnerability by allowing any user to withdraw
    // Ether from another user's account without any authorization
    function unprotectedWithdraw(address payable _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // Fallback function to allow the contract to receive Ether
    receive() external payable {}
}
