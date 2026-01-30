pragma solidity ^0.8.0;
contract SudokuPlonkVerifier {
    
    uint32 constant n =   32768;
    uint16 constant nPublic =  81;
    uint16 constant nLagrange = 81;
    
    uint256 constant Qmx = 10927825355279323819909025888497523658919746891547457607568249713166370480599;
