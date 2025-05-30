pragma solidity 0.8.0;
contract FflonkVerifier {
    uint32 constant n     = 16777216; // Domain size
    uint256 constant k1   = 2;   // Plonk k1 multiplicative factor to force distinct cosets of H
    uint256 constant k2   = 3;   // Plonk k2 multiplicative factor to force distinct cosets of H
