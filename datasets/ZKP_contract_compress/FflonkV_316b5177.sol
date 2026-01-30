pragma solidity 0.8.0;
contract FflonkVerifier {
    uint32 constant n     = 16777216; // Domain size
    uint256 constant k1   = 2;   // Plonk k1 multiplicative factor to force distinct cosets of H
    uint256 constant k2   = 3;   // Plonk k2 multiplicative factor to force distinct cosets of H
pragma solidity ^0.8.0;
library Pairing {
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    uint256 constant qf   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant G1x  = 1;
    uint256 constant G1y  = 2;
    uint256 constant G2x1 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
        Proof memory proof,
        VerifyingKey memory vk
    ) internal view returns (uint256) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
