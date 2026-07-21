/*@vulnerable_(SWC: 124)_at_lines: 44*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPAuthorization {
    struct ZKProof {
        uint256[2] a;
        uint256[2] b;
        uint256[2] c;
    }

    address public admin;
    mapping(address => bool) public authorizedUsers;

    event UserAuthorized(address user);
    event OwnershipChanged(address oldAdmin, address newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Fake ZKP verification logic for demonstration.
    // In practice, this should be replaced by a robust cryptographic verification mechanism.
    function verifyProof(ZKProof memory proof) internal pure returns (bool) {
        // Incorrect verification logic: just checks that proof values are non-zero.
        return proof.a[0] != 0 && proof.b[0] != 0 && proof.c[0] != 0;
    }

    /*@vulnerable_(SWC: 124)_at_lines: 44
    Vulnerability: Insufficient validation of cryptographic proof. The verifyProof function is too simplistic and 
    allows any non-zero proof to pass as valid. This opens up the contract to attacks where malicious users 
    can submit arbitrary data to get authorized.
    */
    function authorizeUser(ZKProof memory proof) public {
        require(verifyProof(proof), "Proof verification failed");
        authorizedUsers[msg.sender] = true;
        emit UserAuthorized(msg.sender);
    }

    function changeAdmin(address newAdmin) public onlyAdmin {
        emit OwnershipChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function revokeAuthorization(address user) public onlyAdmin {
        authorizedUsers[user] = false;
    }

    function isUserAuthorized(address user) public view returns (bool) {
        return authorizedUsers[user];
    }
}
