/*@vulnerable_(SWC: 121)_at_lines: 58*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPPermission {
    address public contractOwner;

    // ZKP proof structure for permission authentication
    struct PermissionProof {
        uint256 permissionId;
        uint256 secret;
        uint256 permissionHash;
    }

    event PermissionVerified(address indexed prover, uint256 permissionId, bool success);

    // Constructor sets the contract deployer as the owner
    constructor() {
        contractOwner = msg.sender;
    }

    // ZKP-based permission verification (simplified)
    function verifyPermission(PermissionProof memory proof) public returns (bool) {
        // Verify if the permission hash matches the permissionId and secret
        bool success = (proof.permissionHash == uint256(keccak256(abi.encodePacked(proof.permissionId, proof.secret))));
        emit PermissionVerified(msg.sender, proof.permissionId, success);
        return success;
    }

    // Allows the owner to change the contract ownership
    function changeOwner(address newOwner) public {
        require(msg.sender == contractOwner, "Only the owner can change ownership");
        contractOwner = newOwner;
    }

    // Allows the owner to withdraw contract funds
    function withdrawFunds() public {
        require(msg.sender == contractOwner, "Only the owner can withdraw funds");
        payable(contractOwner).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 58*/
    // Vulnerable fallback function: allows unrestricted Ether transfer
    fallback() external payable {
        // Ether is accepted without restrictions
    }

    // Vulnerable receive function: also allows Ether transfers with no checks
    receive() external payable {
        // Ether is accepted with no restrictions
    }
}
