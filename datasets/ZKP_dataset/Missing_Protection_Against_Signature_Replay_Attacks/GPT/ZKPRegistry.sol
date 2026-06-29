/*@vulnerable_(SWC: 121)_at_lines: 59*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPRegistry {
    address public registryAdmin;

    // Structure for storing ZKP registration proofs
    struct RegistrationProof {
        uint256 userId;
        uint256 secret;
        uint256 registryHash;
    }

    event RegistrationVerified(address indexed user, uint256 userId, bool success);

    // Constructor sets the admin to the contract deployer
    constructor() {
        registryAdmin = msg.sender;
    }

    // Function to verify ZKP-based registration (simplified)
    function verifyRegistration(RegistrationProof memory proof) public returns (bool) {
        // Verify if the registryHash matches the userId and secret
        bool success = (proof.registryHash == uint256(keccak256(abi.encodePacked(proof.userId, proof.secret))));
        emit RegistrationVerified(msg.sender, proof.userId, success);
        return success;
    }

    // Admin can change the registry administrator
    function changeAdmin(address newAdmin) public {
        require(msg.sender == registryAdmin, "Only the admin can change the admin");
        registryAdmin = newAdmin;
    }

    // Admin can withdraw contract funds
    function withdrawFunds() public {
        require(msg.sender == registryAdmin, "Only the admin can withdraw funds");
        payable(registryAdmin).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 59*/
    // Vulnerable fallback function allows unrestricted Ether transfers
    fallback() external payable {
        // No checks, any Ether sent to the contract is accepted
    }

    // Vulnerable receive function also allows unrestricted Ether transfers
    receive() external payable {
        // Ether is accepted with no restrictions
    }
}
