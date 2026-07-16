/*@vulnerable_(SWC: 107)_at_lines: 44*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ZKP Verifier interface
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPMemberBenefit {
    IVerifier public verifier;
    mapping(address => uint256) public memberBenefits; // Stores benefit amounts for each member
    mapping(address => bool) public isMember;  // Tracks whether an address is a registered member
    uint256 public totalBenefitPool; // The total benefit pool amount

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalBenefitPool = 200 ether; // Initialize benefit pool with 200 ETH
    }

    // Anyone can donate to the benefit pool
    function donateToBenefitPool() public payable {
        require(msg.value > 0, "Must donate some Ether");
        totalBenefitPool += msg.value;
    }

    // Admin sets the benefit amount for a user, provided they are a registered member
    function setMemberBenefit(address _member, uint256 _amount) public {
        require(isMember[_member], "Address is not a registered member");
        require(_amount <= totalBenefitPool, "Insufficient funds in benefit pool");
        memberBenefits[_member] = _amount;
    }

    // Admin marks an address as a registered member
    function registerMember(address _member) public {
        isMember[_member] = true;
    }

    // Members can claim benefits using ZKP verification
    function claimMemberBenefit(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(isMember[msg.sender], "User is not a member");
        require(memberBenefits[msg.sender] >= amount, "Insufficient benefit balance");

        // ZKP verification to ensure user is eligible to claim benefits
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Benefit transfer failed");

        // Update member's benefit balance and total benefit pool
        memberBenefits[msg.sender] -= amount;
        totalBenefitPool -= amount;
    }

    // View the benefit balance available for the user
    function getMemberBenefitBalance() public view returns (uint256) {
        return memberBenefits[msg.sender];
    }
}
