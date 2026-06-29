/*@vulnerable_(SWC: 105)_at_lines: 92*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPProofOfOwnership {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    // Function to deposit Ether into the contract
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Simulate a ZKP-based ownership proof verification using a public key and a proof hash
    function verifyProofOfOwnership(bytes32 publicKey, bytes32 proof) public pure returns (bool) {
        // In a real ZKP system, this would verify ownership through cryptographic checks
        return keccak256(abi.encodePacked(publicKey)) == proof;
    }

    // ZKP-based function to transfer funds if the proof of ownership is valid
    function transferWithZKP(
        address _recipient,
        uint256 _amount,
        bytes32 publicKey,
        bytes32 proof
    ) public {
        require(verifyProofOfOwnership(publicKey, proof), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }

    // @vulnerable_(SWC: 105)_at_lines: 92
    // Unprotected Ether withdrawal function
    // This introduces the SWC-105 vulnerability by allowing any user to withdraw funds
    // from another user's balance without any authentication or ownership checks
    function unsafeWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    // Fallback function to allow the contract to receive Ether
    receive() external payable {}
}
