    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
pragma solidity ^0.5.0;
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
pragma solidity ^0.5.11;
interface IERC777 {
    
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function granularity() external view returns (uint256);
    
    function totalSupply() external view returns (uint256);
