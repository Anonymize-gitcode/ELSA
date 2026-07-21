/*@vulnerable_(SWC: 105)_at_lines: 75*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPValidator {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Function to deposit Ether into the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Dummy ZKP verifier - simulating a simple zero-knowledge proof validation
    function validateProof(bytes32 publicData, uint256 secretProof) public pure returns (bool) {
        // A simplified ZKP validation logic
        return uint256(keccak256(abi.encodePacked(publicData))) == secretProof;
    }

    // ZKP-based fund transfer
    // Requires the user to provide a valid ZKP before transferring funds
    function transferWithZKP(
        address _recipient, 
        uint256 _amount, 
        bytes32 publicData, 
        uint256 secretProof
    ) public {
        require(validateProof(publicData, secretProof), "Zero-knowledge proof is invalid");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    // @vulnerable_(SWC: 105)_at_lines: 75
    // Unprotected Ether withdrawal
    // This function introduces the SWC-105 vulnerability as it allows anyone to withdraw
    // Ether from another user's balance without proper authorization checks
    function unprotectedWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // Fallback function to allow the contract to receive Ether
    receive() external payable {}
}
