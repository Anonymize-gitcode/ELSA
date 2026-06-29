/*@vulnerable_(SWC: 110)_at_lines: 38*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferVerifier {
    function verifyTransferProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}

contract ZKPWithTransferAndSWC110 {
    ITransferVerifier public verifier;
    mapping(address => uint256) public balances;
    uint256 public maxTransferAmount = 1000;

    event TransferSuccessful(address indexed sender, address indexed receiver, uint256 amount);

    constructor(address verifierAddress) {
        verifier = ITransferVerifier(verifierAddress);
        // Initialize balances for demonstration purposes
        balances[msg.sender] = 5000;
    }

    // Function to verify the ZKP transfer proof and execute the transfer
    function verifyAndTransfer(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input,
        address receiver,
        uint256 amount
    ) public {
        // Ensure sender has sufficient balance
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Verify the ZKP transfer proof
        bool proofValid = verifier.verifyTransferProof(a, b, c, input);

        // If proof is valid, perform the transfer
        if (proofValid) {
            balances[msg.sender] -= amount;
            balances[receiver] += amount;

            // Ensure the transfer amount does not exceed the predefined limit
            assert(amount <= maxTransferAmount); 

            emit TransferSuccessful(msg.sender, receiver, amount);
        }
    }

    // Function to retrieve the balance of an account
    function getBalance(address account) public view returns (uint256) {
        return balances[account];
    }
}
