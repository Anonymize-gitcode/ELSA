/*@vulnerable_(SWC: 124)_at_lines: 46*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPWeakValidation {
    struct ZKProof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public admin;
    mapping(address => bool) public validatedUsers;

    event UserValidated(address user);
    event OwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    // Weak ZKP validation function
    function checkProof(ZKProof memory proof, uint256[] memory publicInput) internal pure returns (bool) {
        // Incorrect validation: It only checks if the proof values match the public inputs' length, ignoring actual proof verification.
        return proof.a[0] == publicInput.length && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 46
    Vulnerability: The checkProof function only checks simple length comparison and non-zero checks, 
    which do not provide any actual cryptographic validation, allowing attackers to submit arbitrary proofs and bypass validation.
    */
    function validateUser(ZKProof memory proof, uint256[] memory publicInput) public {
        require(checkProof(proof, publicInput), "Invalid proof");
        validatedUsers[msg.sender] = true;
        emit UserValidated(msg.sender);
    }

    function isUserValidated(address user) public view returns (bool) {
        return validatedUsers[user];
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "New admin cannot be the zero address");
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    function revokeUserValidation(address user) public onlyAdmin {
        validatedUsers[user] = false;
    }
}
