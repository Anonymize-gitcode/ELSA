/*@vulnerable_(SWC: 121)_at_lines: 44*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPVulnerable {
    address public verifier;
    
    // Structure to store a zero-knowledge proof
    struct ZKProof {
        uint256 x; // Some input
        uint256 y; // Another input
        uint256 z; // Expected result
    }

    event ProofSubmitted(address indexed sender, bool valid);

    // Set the verifier to the contract deployer
    constructor() {
        verifier = msg.sender;
    }

    // Modifier to restrict access to only the verifier
    modifier onlyVerifier() {
        require(msg.sender == verifier, "Not authorized");
        _;
    }

    // Function to verify a ZKProof, simplistic example
    function verifyProof(ZKProof memory proof) public returns (bool) {
        // A basic check as an example of ZKP verification
        bool isValid = (proof.x * proof.y == proof.z);
        emit ProofSubmitted(msg.sender, isValid);
        return isValid;
    }

    // Allow verifier to change the verifier address
    function changeVerifier(address newVerifier) public onlyVerifier {
        verifier = newVerifier;
    }

    // Withdraw Ether from the contract (only allowed for the verifier)
    function withdrawFunds() public onlyVerifier {
        payable(verifier).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 44*/
    // This fallback function is vulnerable because it allows unrestricted Ether transfers
    fallback() external payable {
        // No restrictions, accepts Ether from any source
    }

    // Another way to accept Ether, also vulnerable
    receive() external payable {
        // Accepts Ether without restrictions
    }
}
