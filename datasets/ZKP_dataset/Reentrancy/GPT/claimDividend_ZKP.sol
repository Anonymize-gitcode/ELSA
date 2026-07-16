/*@vulnerable_(SWC:107)_at_lines: 29*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interface for the ZKP Verifier
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}

contract ZKPDividend {
    IVerifier public verifier;
    mapping(address => uint256) public dividends; // Amount of dividends available for each user
    uint256 public totalDividendPool; // Total dividend pool

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalDividendPool = 500 ether; // Initial dividend pool set to 500 ETH
    }

    // Admin function to set the dividend amount for a shareholder
    function setDividendForShareholder(address _shareholder, uint256 _amount) public {
        require(_amount <= totalDividendPool, "Insufficient dividend pool");
        dividends[_shareholder] = _amount;
    }

    // Allows users to claim dividends through ZKP verification
    function claimDividend(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(dividends[msg.sender] >= amount, "Insufficient dividend balance");

        // Verifies whether the user is eligible to claim dividends using zero-knowledge proof
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");

        // External call before state update
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Dividend transfer failed");

        // Update user's dividend balance and total dividend pool
        dividends[msg.sender] -= amount;
        totalDividendPool -= amount;
    }

    // Users can query their available dividend balance through this function
    function getDividendBalance() public view returns (uint256) {
        return dividends[msg.sender];
    }

    // Admin function to add more funds to the dividend pool
    function addToDividendPool() public payable {
        require(msg.value > 0, "Must send some Ether");
        totalDividendPool += msg.value;
    }
}
