/*@vulnerable_(SWC: 121)_at_lines: 42*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKProofContract {
    address public owner;

    // Example structure to hold proof data
    struct Proof {
        uint256 a;
        uint256 b;
        uint256 c;
    }

    // Event to log verification results
    event ProofVerified(address verifier, bool success);

    // The constructor sets the contract deployer as the owner
    constructor() {
        owner = msg.sender;
    }

    // A simple ZKP verification function (for illustration purposes)
    // In real ZKP scenarios, this would be much more complex
    function verifyZKProof(Proof memory proof) public returns (bool) {
        // Placeholder for a real ZKP verification logic
        bool success = (proof.a + proof.b == proof.c); // Simple check as an example
        emit ProofVerified(msg.sender, success);
        return success;
    }

    // Allow the contract owner to withdraw Ether from the contract
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 42*/
    // This fallback function is vulnerable because it lacks proper protection
    fallback() external payable {
        // Contract accepts Ether without restrictions, which is vulnerable
    }

    receive() external payable {
        // Accept Ether from any source, no restrictions
    }
}
