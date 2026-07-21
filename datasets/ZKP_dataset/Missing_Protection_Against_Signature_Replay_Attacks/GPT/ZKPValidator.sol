/*@vulnerable_(SWC: 121)_at_lines: 48*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ZKPValidator {
    address public validator;
    uint256 public verificationCounter;

    // ZKP proof structure
    struct Proof {
        uint256 p1;
        uint256 p2;
        uint256 expectedResult;
    }

    event ProofValidated(address indexed sender, bool success, uint256 count);

    constructor() {
        validator = msg.sender;
        verificationCounter = 0;
    }

    // Function to validate a proof (simple illustrative example)
    function validateProof(Proof memory proof) public returns (bool) {
        // A basic check (in a real scenario, this would be more complex)
        bool isValid = (proof.p1 ** 2 + proof.p2 == proof.expectedResult);
        verificationCounter++;
        emit ProofValidated(msg.sender, isValid, verificationCounter);
        return isValid;
    }

    // Function to change the validator address
    function changeValidator(address newValidator) public {
        require(msg.sender == validator, "Only the current validator can change");
        validator = newValidator;
    }

    // Function to withdraw contract balance (only validator can do this)
    function withdrawBalance() public {
        require(msg.sender == validator, "Only the validator can withdraw");
        payable(validator).transfer(address(this).balance);
    }

    /*@vulnerable_(SWC: 121)_at_lines: 48*/
    // Vulnerable fallback function, allows unrestricted Ether transfers
    fallback() external payable {
        // Accepts Ether without any restrictions or checks
    }

    // Vulnerable receive function, accepts Ether without restrictions
    receive() external payable {
        // No conditions for receiving Ether
    }
}
