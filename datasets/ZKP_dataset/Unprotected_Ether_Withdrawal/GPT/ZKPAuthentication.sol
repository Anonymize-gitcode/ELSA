/*@vulnerable_(SWC: 105)_at_lines: 84*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAuthentication {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether into the contract, credited to the user's balance
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Dummy ZKP verifier - verifies if a proof matches a hashed secret
    // In a real ZKP system, this would involve more advanced cryptography
    function zkVerify(bytes32 commitment, uint256 secret) public pure returns (bool) {
        return keccak256(abi.encodePacked(secret)) == commitment;
    }

    // ZKP-based withdrawal function, where the user needs to prove their identity
    // by providing a valid zero-knowledge proof
    function withdrawWithZKP(
        uint256 _amount, 
        bytes32 commitment, 
        uint256 secret
    ) public {
        require(zkVerify(commitment, secret), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to transfer Ether");
    }

    // @vulnerable_(SWC: 105)_at_lines: 84
    // Unprotected Ether withdrawal
    // This function introduces SWC-105 vulnerability by allowing anyone to withdraw funds
    // from any user's balance without any authorization checks
    function unsafeWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
