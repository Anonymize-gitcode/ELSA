/*@vulnerable_(SWC: 105)_at_lines: 81*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPProver {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Deposit Ether into the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // ZKP Verifier - simple simulation of a proof verification
    function verifyProof(uint256 publicValue, bytes32 hashedSecret) public pure returns (bool) {
        // In a real-world application, this would involve complex ZKP cryptography
        return keccak256(abi.encodePacked(publicValue)) == hashedSecret;
    }

    // ZKP-based transfer of Ether, requiring a valid proof
    function transferWithZKP(
        address _recipient, 
        uint256 _amount, 
        uint256 publicValue, 
        bytes32 hashedSecret
    ) public {
        require(verifyProof(publicValue, hashedSecret), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    // @vulnerable_(SWC: 105)_at_lines: 81
    // Unprotected Ether withdrawal function
    // This introduces the SWC-105 vulnerability by allowing anyone to withdraw funds
    // from another user's balance without proper authorization
    function insecureWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
