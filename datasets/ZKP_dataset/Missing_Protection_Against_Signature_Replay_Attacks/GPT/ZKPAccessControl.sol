/*@vulnerable_(SWC: 121)_at_lines: 60*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAccessControl {
    address public admin;

    // Structure for storing ZKP-based access control proofs
    struct AccessProof {
        uint256 accessId;
        uint256 secret;
        uint256 accessHash;
    }

    event AccessGranted(address indexed user, uint256 accessId, bool success);

    // Constructor sets the contract deployer as the admin
    constructor() {
        admin = msg.sender;
    }

    // Function to verify access using ZKP (simplified)
    function verifyAccess(AccessProof memory proof) public returns (bool) {
        // Verify if the accessHash matches the accessId and secret
        bool success = (proof.accessHash == uint256(keccak256(abi.encodePacked(proof.accessId, proof.secret))));
        emit AccessGranted(msg.sender, proof.accessId, success);
        return success;
    }

    // Allows the admin to change the admin address
    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin, "Only the admin can change the admin");
        admin = newAdmin;
    }

    // Allows the admin to withdraw funds from the contract
    function withdrawFunds() public {
        require(msg.sender == admin, "Only the admin can withdraw funds");
        payable(admin).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 60*/
    // Vulnerable fallback function: allows unrestricted Ether transfers
    fallback() external payable {
        // Ether is accepted without any checks or restrictions
    }

    // Vulnerable receive function: also allows unrestricted Ether transfers
    receive() external payable {
        // Ether is accepted from any sender without conditions
    }
}
