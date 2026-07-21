/*@vulnerable_(SWC: 107)_at_lines: 33*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the ZKP verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPInsuranceClaim {
    IVerifier public verifier;
    mapping(address => uint256) public claims; // Tracks the insurance claim amounts for each user
    uint256 public totalClaimPool; // Total amount in the insurance claim pool

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalClaimPool = 300 ether; // Initial claim pool set to 300 ETH
    }

    // Users can pay premiums to increase the insurance claim pool
    function payPremium() public payable {
        require(msg.value > 0, "Must send some Ether as premium");
        totalClaimPool += msg.value;
    }

    // Admin sets the insurance claim amount for a specific user
    function setInsuranceClaim(address _user, uint256 _amount) public {
        require(_amount <= totalClaimPool, "Insufficient claim pool");
        claims[_user] = _amount;
    }

    // Users claim insurance funds after passing ZKP verification
    function claimInsurance(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(claims[msg.sender] >= amount, "Insufficient claim balance");

        // Verify ZKP proof for eligibility
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // Execute the insurance payout to the user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Insurance payout failed");

        // Update the user's claim balance and the total claim pool
        claims[msg.sender] -= amount;
        totalClaimPool -= amount;
    }

    // Query the current claim balance of a user
    function getClaimBalance() public view returns (uint256) {
        return claims[msg.sender];
    }

    // Admin can add funds to the insurance claim pool
    function addToClaimPool() public payable {
        require(msg.value > 0, "Must send some Ether");
        totalClaimPool += msg.value;
    }
}
