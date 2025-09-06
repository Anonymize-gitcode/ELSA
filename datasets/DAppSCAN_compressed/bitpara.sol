pragma solidity ^0.4.18;

contract Owned { address public owner; address public newOwner; event OwnershipTransferProposed(address indexed _from, address indexed _to); event OwnershipTransferred(address indexed _from, address indexed _to); modifier onlyOwner { require(msg.sender == owner); _; }

function Owned() public { owner = msg.sender; }

function transferOwnership(address _newOwner) public onlyOwner { require(_newOwner != owner); require(_newOwner != address(0x0)); OwnershipTransferProposed(owner, _newOwner); newOwner = _newOwner; } function acceptOwnership() public { require(msg.sender == newOwner); OwnershipTransferred(owner, newOwner); owner = newOwner; }

contract Pausable is Owned { event Pause(); event Unpause(); bool public paused = false; modifier whenNotPaused() { require(!paused); _; }

contract ERC20Interface { event Transfer(address indexed _from, address indexed _to, uint256 _value); event Approval(address indexed _owner, address indexed _spender, uint256 _value); function totalSupply() public view returns (uint256); function balanceOf(address _owner) public view returns (uint256 balance); function allowance(address _owner, address _spender) public view returns (uint256 remaining); function transfer(address _to, uint256 _value) public returns (bool success); function transferFrom(address _from, address _to, uint256 _value) public returns (bool success); function approve(address _spender, uint256 _value) public returns (bool success); }

contract BasicToken is ERC20Interface, Owned { using SafeMath for uint256; string public constant name = "Bitpara TRY"; string public constant symbol = "BTRY"; uint8 public constant decimals = 6; uint256 public tokensIssuedTotal = 0; uint256 public fee = 0; mapping(address => uint256) balances; function changeFee(uint256 _fee) onlyOwner public { require(_fee <= 10000000); fee = _fee; }

contract StandardToken is BasicToken { mapping(address => mapping(address => uint256)) internal allowed; function allowance(address _owner, address _spender) public view returns (uint256 remaining) { return allowed[_owner][_spender]; }

contract BanList is Owned, StandardToken { mapping(address => bool) public checkBan; function getBanStatus(address _unclear) external view returns (bool) { return checkBan[_unclear]; }

contract PausableToken is BanList, Pausable { function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) { require(!checkBan[msg.sender]); return super.transfer(_to, _value); }

contract MintableToken is PausableToken { event Mint(address indexed owner, uint _amount); function mint(uint256 _amount) onlyOwner public returns (bool) { tokensIssuedTotal = tokensIssuedTotal.add(_amount); balances[owner] = balances[owner].add(_amount); Mint(owner, _amount); Transfer(0, owner, _amount); return true; }

contract BurnableToken is MintableToken { event Burn(address indexed owner, uint256 _value); function burn(uint256 _value) onlyOwner public returns (bool) { require(_value > 0); balances[owner] = balances[owner].sub(_value); tokensIssuedTotal = tokensIssuedTotal.sub(_value); Burn(owner, _value); return true; }

contract Bitpara is BurnableToken { function transferToOwner(address _from, uint256 _value) onlyOwner public returns (bool) { balances[_from] = balances[_from].sub(_value); balances[owner] = balances[owner].add(_value); Transfer(_from, owner, _value); return true; }