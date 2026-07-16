    return allowed[_owner][_spender];
  }
  
  
}
contract daoPOLSKAtokens{
    string public name = "DAO POLSKA TOKEN version 1";
    string public symbol = "DPL";
    uint8 public constant decimals = 18;  // 18 decimal places, the same as ETC/ETH/HEE.
    address public owner;
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
pragma solidity ^0.4.11;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}
contract ERC20 {
  uint public totalSupply;
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
