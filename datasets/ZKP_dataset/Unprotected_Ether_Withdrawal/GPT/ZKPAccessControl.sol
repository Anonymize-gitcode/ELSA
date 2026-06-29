/*@vulnerable_(SWC: 105)_at_lines: 88*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAccessControl {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether into the contract and credit it to the sender's balance
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Dummy ZKP verifier to simulate verification of a proof of identity
    // In real cases, this would involve verifying a cryptographic zero-knowledge proof
    function verifyZKP(bytes32 identityHash, bytes32 proof) public pure returns (bool) {
        return keccak256(abi.encodePacked(proof)) == identityHash;
    }

    // ZKP-based function to unlock funds, where the user provides a valid proof of identity
    function unlockFundsWithZKP(
        address _recipient, 
        uint256 _amount, 
        bytes32 identityHash, 
        bytes32 proof
    ) public {
        require(verifyZKP(identityHash, proof), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // @vulnerable_(SWC: 105)_at_lines: 88
    // Unprotected Ether withdrawal function
    // This introduces the SWC-105 vulnerability as it allows any user to withdraw
    // Ether from another user's account without permission or validation
    function insecureWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
