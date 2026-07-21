/*@vulnerable_(SWC:107)_at_lines: 30*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Interface for ZKP verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPRefund {
    IVerifier public verifier;
    mapping(address => uint256) public prepayments; // Prepayment amount for each user
    uint256 public totalRefundPool; // Total refundable pool

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalRefundPool = 100 ether; // Initialize the refund pool
    }

    // Users can make prepayments, adding to the refund pool
    function makePrepayment() public payable {
        require(msg.value > 0, "Must send some Ether");
        prepayments[msg.sender] += msg.value;
        totalRefundPool += msg.value;
    }

    // Admin can set refund amounts for users
    function setRefundForUser(address _user, uint256 _amount) public {
        require(_amount <= prepayments[_user], "Refund exceeds prepayment");
    }

    // Users claim refunds using ZKP verification
    function claimRefund(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(prepayments[msg.sender] >= amount, "Insufficient prepayment balance");

        // ZKP verification to check if user is eligible for a refund
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // External call before updating user's balance
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Refund transfer failed");

        // Update user's prepayment balance and total refund pool
        prepayments[msg.sender] -= amount;
        totalRefundPool -= amount;
    }

    // View user's prepayment balance
    function getPrepaymentBalance() public view returns (uint256) {
        return prepayments[msg.sender];
    }
}
