/*@vulnerable_(SWC: 101)_at_lines: 34*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAccessControl {
    address public owner;
    mapping(address => bool) public accessGranted;

    constructor() {
        owner = msg.sender;
    }

    // Function to request access using a zero-knowledge proof
    function requestAccess(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid proof");
        require(!accessGranted[msg.sender], "Access already granted");

        // Grant access after successful proof verification
        accessGranted[msg.sender] = true;
    }

    // Simple mock verification function for ZKP
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        // This is a mock logic to simulate ZKP verification
        return (proof[0] + proof[1]) == (input[0] + input[1]);
    }

    // Function to withdraw Ether after accessing the system, vulnerable to SWC-101
    /*@vulnerable_(SWC: 101)_at_lines: 34*/
    function withdrawAfterAccess(uint256 amount) public {
        require(accessGranted[msg.sender], "You must have access to withdraw funds");
        require(amount <= address(this).balance, "Insufficient contract balance");

        // Vulnerable code: Reentrancy vulnerability (SWC-101)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State is updated after the external call, making it vulnerable to reentrancy attacks
        accessGranted[msg.sender] = false;
    }

    // Function to deposit Ether into the contract
    function deposit() public payable {}

    // Allow the contract to receive Ether
    receive() external payable {}
}
