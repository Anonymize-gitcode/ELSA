/*@vulnerable_(SWC: 107)_at_lines: 36*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for ZKP Verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPBenefit {
    IVerifier public verifier;
    mapping(address => uint256) public benefits; // Benefit balance for each user
    uint256 public totalBenefitPool; // Total benefit pool

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalBenefitPool = 500 ether; // Initialize benefit pool with 500 ETH
    }

    // Donation function, anyone can add funds to the benefit pool
    function donateToBenefitPool() public payable {
        require(msg.value > 0, "Must donate some Ether");
        totalBenefitPool += msg.value;
    }

    // Admin can set a user's claimable benefit amount
    function setUserBenefit(address _user, uint256 _amount) public {
        require(_amount <= totalBenefitPool, "Insufficient pool balance");
        benefits[_user] = _amount;
    }

    // Users can claim their benefit through ZKP verification
    function claimBenefit(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(benefits[msg.sender] >= amount, "Insufficient benefit balance");

        // Verify user's eligibility through Zero-Knowledge Proof
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // Transfer benefit to the user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Benefit transfer failed");

        // Update user's benefit balance and the total benefit pool
        benefits[msg.sender] -= amount;
        totalBenefitPool -= amount;
    }

    // Get the claimable benefit amount for the user
    function getUserBenefit() public view returns (uint256) {
        return benefits[msg.sender];
    }
}
