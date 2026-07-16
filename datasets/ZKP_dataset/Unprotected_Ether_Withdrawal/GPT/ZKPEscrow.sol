/*@vulnerable_(SWC: 105)_at_lines: 74*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPEscrow {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether into the contract, credited to the sender's balance
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Dummy zero-knowledge proof (ZKP) verifier
    // Simulating a zk-SNARK verification that returns true if publicInput is valid
    function zkSnarkVerify(bytes32 publicInput, bytes32 proofHash) public pure returns (bool) {
        // In a real implementation, this would involve cryptographic proof checks
        return keccak256(abi.encodePacked(publicInput)) == proofHash;
    }

    // ZKP-based fund release function
    // Allows release of funds based on a successful zero-knowledge proof
    function releaseFundsWithZKP(
        address payable _recipient, 
        uint256 _amount, 
        bytes32 publicInput, 
        bytes32 proofHash
    ) public {
        require(zkSnarkVerify(publicInput, proofHash), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to transfer Ether");
    }

    // @vulnerable_(SWC: 105)_at_lines: 74
    // Unprotected Ether withdrawal function
    // This introduces the SWC-105 vulnerability, allowing any user to withdraw funds
    // from any other user's balance without proper validation
    function insecureWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
