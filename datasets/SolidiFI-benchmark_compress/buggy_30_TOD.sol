pragma solidity ^0.5.11;
interface IERC777 {
    
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function granularity() external view returns (uint256);
    
    function totalSupply() external view returns (uint256);
