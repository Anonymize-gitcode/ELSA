/*@vulnerable_(SWC: 105)_at_lines: 90*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPIdentityVerification {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit function to allow users to deposit Ether into the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // ZKP-based identity verification using a secret commitment and public key
    function verifyZKPCommitment(bytes32 publicKey, bytes32 commitment) public pure returns (bool) {
        // In a real-world scenario, this would verify the user's identity using cryptography
        return keccak256(abi.encodePacked(publicKey)) == commitment;
    }

    // ZKP-based function for transferring Ether upon successful proof of identity
    function transferWithZKP(
        address _recipient,
        uint256 _amount,
        bytes32 publicKey,
        bytes32 commitment
    ) public {
        require(verifyZKPCommitment(publicKey, commitment), "Zero-knowledge proof verification failed");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    // @vulnerable_(SWC: 105)_at_lines: 90
    // Unprotected Ether withdrawal function
    // This introduces the SWC-105 vulnerability by allowing any user to withdraw
    // Ether from any other user's account without any proper validation or restrictions
    function unprotectedWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // Fallback function to allow the contract to receive Ether
    receive() external payable {}
}
