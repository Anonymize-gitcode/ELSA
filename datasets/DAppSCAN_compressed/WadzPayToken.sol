pragma solidity ^0.8.0;

contract Context { function _msgSender() internal view virtual returns (address) { return msg.sender; }

contract Ownable { address private _owner; event OwnershipTransferred( address indexed previousOwner, address indexed newOwner ); constructor() { address msgSender = msg.sender; _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }

interface IERC20 { function totalSupply() external view returns (uint256); function balanceOf(address account) external view returns (uint256); function transfer(address recipient, uint256 amount) external returns (bool); function allowance(address owner, address spender) external view returns (uint256); function approve(address spender, uint256 amount) external returns (bool); function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool); event Transfer(address indexed from, address indexed to, uint256 value); event Approval(address indexed owner, address indexed spender, uint256 value); }

interface IERC20Metadata is IERC20 { function name() external view returns (string memory); function symbol() external view returns (string memory); function decimals() external view returns (uint8); }

struct WhitelistRound { uint256 duration; uint256 amountMax; mapping(address => bool) addresses; mapping(address => uint256) purchased; }