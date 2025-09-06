pragma solidity ^0.5.17;

contract TokenERC20 { string public name; string public symbol; uint8 public decimals = 18; uint256 public totalSupply; mapping (address => uint256) public balanceOf; mapping (address => mapping (address => uint256)) public allowance; event Transfer(address indexed from, address indexed to, uint256 value); event Approval(address indexed _owner, address indexed _spender, uint256 _value); event Burn(address indexed from, uint256 value); constructor( uint256 initialSupply, string memory tokenName, string memory tokenSymbol ) public { totalSupply = initialSupply * 10 ** uint256(decimals); balanceOf[msg.sender] = totalSupply; name = tokenName; symbol = tokenSymbol; }

function _transfer(address _from, address _to, uint _value) internal { require(_to != address(0x0)); require(balanceOf[_from] >= _value); require(balanceOf[_to] + _value >= balanceOf[_to]); uint previousBalances = balanceOf[_from] + balanceOf[_to]; balanceOf[_from] -= _value; balanceOf[_to] += _value; emit Transfer(_from, _to, _value); assert(balanceOf[_from] + balanceOf[_to] == previousBalances); }

contract ZortCoin is TokenERC20 { constructor () public TokenERC20(1000000000,"Zort Coin", "ZORT") { }

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }