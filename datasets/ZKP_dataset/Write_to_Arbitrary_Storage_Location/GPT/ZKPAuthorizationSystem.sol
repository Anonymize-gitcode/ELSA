/*@vulnerable_(SWC: 124)_at_lines: 66*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAuthorizationSystem {
    struct ZKProof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public admin;
    mapping(address => bool) public authorizedEntities;

    event EntityAuthorized(address indexed entity);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Simplistic and vulnerable ZKP verification function
    function validateZKProof(ZKProof memory proof, uint256 input) internal pure returns (bool) {
        // Vulnerable logic: only checks a simple condition that is not sufficient for true ZKP verification
        return proof.a[1] == input && proof.b[0] != 0 && proof.c[1] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 66
    Vulnerability: The validateZKProof function does not implement proper cryptographic proof verification, 
    allowing attackers to submit arbitrary proofs and gain unauthorized access.
    */
    function authorizeEntity(ZKProof memory proof, uint256 input) public {
        require(validateZKProof(proof, input), "Invalid proof");
        authorizedEntities[msg.sender] = true;
        emit EntityAuthorized(msg.sender);
    }

    function isEntityAuthorized(address entity) public view returns (bool) {
        return authorizedEntities[entity];
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    function revokeAuthorization(address entity) public onlyAdmin {
        authorizedEntities[entity] = false;
    }
}
