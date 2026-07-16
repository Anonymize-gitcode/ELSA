/*@vulnerable_(SWC: 105)_at_lines: 47*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleZKP {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit function to add ether to the user's balance
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Dummy zero-knowledge proof verifier (for illustration purposes)
    // In real-world ZKP, this would involve cryptographic proof verification
    function verifyProof(bytes memory proof) public pure returns (bool) {
        // Assume the proof is valid for this example
        return true;
    }

    // ZKP-based fund transfer
    // The sender must provide a valid zero-knowledge proof to transfer funds
    function transferWithZKP(
        address _recipient,
        uint256 _amount,
        bytes memory proof
    ) public {
        require(verifyProof(proof), "Invalid ZKP proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    // @vulnerable_(SWC: 105)_at_lines: 47
    // Unprotected withdrawal function
    // This function introduces the SWC-105 vulnerability by allowing any user to withdraw funds on behalf of others
    function withdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
