pragma solidity 0.4.22;
contract EIP20Interface {
    
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
function unhandledsend_unchk14(address payable callee) public {
    callee.send(5 ether);
  }
    function transfer(address _to, uint256 _value) public returns (bool success);
function bug_unchk30() public{
uint receivers_unchk30;
address payable addr_unchk30;
if (!addr_unchk30.send(42 ether))
	{receivers_unchk30 +=1;}
else
	{revert();}
}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
bool public payedOut_unchk8 = false;
address payable public winner_unchk8;
uint public winAmount_unchk8;
function sendToWinner_unchk8() public {
        require(!payedOut_unchk8);
        winner_unchk8.send(winAmount_unchk8);
        payedOut_unchk8 = true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success);
function bug_unchk39(address payable addr) public
      {addr.send (4 ether); }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
function my_func_uncheck36(address payable dst) public payable{
        dst.call.value(msg.value)("");
    }
  bool public payedOut_unchk45 = false;
function withdrawLeftOver_unchk45() public {
        require(payedOut_unchk45);
        msg.sender.send(address(this).balance);
    }
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  function callnotchecked_unchk13(address callee) public {
    callee.call.value(1 ether);
  }
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract HotDollarsToken is EIP20Interface {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
  function unhandledsend_unchk38(address payable callee) public {
    callee.send(5 ether);
  }
  mapping (address => uint256) public balances;
  function cash_unchk46(uint roundIndex, uint subpotIndex, address payable winner_unchk46) public{
        uint64 subpot_unchk46 = 3 ether;
        winner_unchk46.send(subpot_unchk46);  //bug
        subpot_unchk46= 0;
}
  mapping (address => mapping (address => uint256)) public allowed;
    
  function UncheckedExternalCall_unchk4 () public
{  address payable addr_unchk4;
   if (! addr_unchk4.send (42 ether))  
      {// comment1;
      }
	else
      {//comment2;
      }
}
  string public name;                   //fancy name: eg Simon Bucks
  function bug_unchk7() public{
address payable addr_unchk7;
if (!addr_unchk7.send (10 ether) || 1==1)
	{revert();}
}
  uint8 public decimals;                //How many decimals to show.
  function my_func_unchk23(address payable dst) public payable{
        dst.send(msg.value);
    }
  string public symbol;                 //An identifier: eg SBX
    constructor() public {
        totalSupply = 3 * 1e28;                        
        name = "HotDollars Token";                          
        decimals = 18;                           
        symbol = "HDS";
        balances[msg.sender] = totalSupply; 
    }
function my_func_unchk35(address payable dst) public payable{
        dst.send(msg.value);
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
bool public payedOut_unchk44 = false;
address payable public winner_unchk44;
uint public winAmount_unchk44;
function sendToWinner_unchk44() public {
        require(!payedOut_unchk44);
        winner_unchk44.send(winAmount_unchk44);
        payedOut_unchk44 = true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
function UncheckedExternalCall_unchk40 () public
{  address payable addr_unchk40;
   if (! addr_unchk40.send (2 ether))  
      {// comment1;
      }
	else
      {//comment2;
      }
}
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
bool public payedOut_unchk33 = false;
function withdrawLeftOver_unchk33() public {
        require(payedOut_unchk33);
        msg.sender.send(address(this).balance);
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }
function bug_unchk27(address payable addr) public
      {addr.send (42 ether); }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
function bug_unchk31() public{
address payable addr_unchk31;
if (!addr_unchk31.send (10 ether) || 1==1)
	{revert();}
}
}