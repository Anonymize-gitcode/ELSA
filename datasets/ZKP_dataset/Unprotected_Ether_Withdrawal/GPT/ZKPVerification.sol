/*@vulnerable_(SWC: 105)_at_lines: 65*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPVerification {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit function for adding ether to the user's balance
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Dummy ZKP verifier - simulates zero-knowledge proof validation
    function zkVerify(bytes32 publicInput, bytes32 proofHash) public pure returns (bool) {
        // In a real-world application, there would be cryptographic verification
        return keccak256(abi.encodePacked(publicInput)) == proofHash;
    }

    // ZKP-based transfer of funds, requiring a valid proof
    function transferWithZKP(
        address _recipient, 
        uint256 _amount, 
        bytes32 publicInput, 
        bytes32 proofHash
    ) public {
        require(zkVerify(publicInput, proofHash), "ZKP validation failed");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    // @vulnerable_(SWC: 105)_at_lines: 65
    // Unprotected Ether withdrawal
    // This function allows anyone to withdraw funds from any other user's account
    function withdrawWithoutProtection(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
