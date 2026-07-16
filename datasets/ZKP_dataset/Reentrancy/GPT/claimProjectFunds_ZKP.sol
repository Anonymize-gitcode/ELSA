/*@vulnerable_(SWC: 107)_at_lines: 35*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the ZKP verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPProjectFunding {
    IVerifier public verifier;
    mapping(address => uint256) public projectFunds; // Funds available for each project or user
    uint256 public totalFundingPool; // Total funding pool for the project

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalFundingPool = 500 ether; // Initialize the project funding pool to 500 ETH
    }

    // Users can contribute to the funding pool
    function contributeToFundingPool() public payable {
        require(msg.value > 0, "Must send some Ether to contribute");
        totalFundingPool += msg.value;
    }

    // Admin allocates funds to a specific project
    function allocateProjectFunding(address _project, uint256 _amount) public {
        require(_amount <= totalFundingPool, "Insufficient funds in the pool");
        projectFunds[_project] = _amount;
    }

    // Users claim project funds through ZKP verification
    function claimProjectFunds(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(projectFunds[msg.sender] >= amount, "Insufficient project funds");

        // Verify the user's eligibility through zero-knowledge proof
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // Transfer funds to the user
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Fund transfer failed");

        // Update the project's fund balance and total funding pool
        projectFunds[msg.sender] -= amount;
        totalFundingPool -= amount;
    }

    // Query the user's available project funds
    function getProjectFunds() public view returns (uint256) {
        return projectFunds[msg.sender];
    }
}
