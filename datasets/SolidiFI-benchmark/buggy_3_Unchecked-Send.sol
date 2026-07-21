/**
 * Source Code first verified at https://etherscan.io on Tuesday, May 7, 2019
 (UTC) */

pragma solidity ^0.5.1;

contract CareerOnToken {
  function bug_unchk_send27() payable public{
      msg.sender.transfer(1 ether);}
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  function bug_unchk_send31() payable public{
      msg.sender.transfer(1 ether);}
  event Approval(address indexed a_owner, address indexed _spender, uint256 _value);
  function bug_unchk_send13() payable public{
      msg.sender.transfer(1 ether);}
  event OwnerChang(address indexed _old,address indexed _new,uint256 _coin_change);
    
  function bug_unchk_send12() payable public{
      msg.sender.transfer(1 ether);}
  uint256 public totalSupply;  
  function bug_unchk_send11() payable public{
      msg.sender.transfer(1 ether);}
  string public name;                   // name, e.g. "My test token"
  function bug_unchk_send1() payable public{
      msg.sender.transfer(1 ether);}
  uint8 public decimals;               // number of decimals the token uses; e.g. 3 means it supports 0.001
  function bug_unchk_send2() payable public{
      msg.sender.transfer(1 ether);}
  string public symbol;               // token symbol, like MTT
  function bug_unchk_send17() payable public{
      msg.sender.transfer(1 ether);}
  address public owner;
    
  function bug_unchk_send3() payable public{
      msg.sender.transfer(1 ether);}
  mapping (address => uint256) internal balances;
  function bug_unchk_send9() payable public{
      msg.sender.transfer(1 ether);}
  mapping (address => mapping (address => uint256)) internal allowed;
    
	// if setPauseStatus sets this variable to TRUE, all transfer transactions will fail
  function bug_unchk_send25() payable public{
      msg.sender.transfer(1 ether);}
  bool isTransPaused=false;
    
    constructor(
        uint256 _initialAmount,
        uint8 _decimalUnits) public 
    {
        owner=msg.sender;// record the contract owner
		if(_initialAmount<=0){
		    totalSupply = 100000000000000000;   // set the initial total supply
		    balances[owner]=totalSupply;
		}else{
		    totalSupply = _initialAmount;   // set the initial total supply
		    balances[owner]=_initialAmount;
		}
		if(_decimalUnits<=0){
		    decimals=2;
		}else{
		    decimals = _decimalUnits;
		}
        name = "CareerOn Chain Token"; 
        symbol = "COT";
    }
function bug_unchk_send19() payable public{
      msg.sender.transfer(1 ether);}
    
    
    function transfer(
        address _to, 
        uint256 _value) public returns (bool success) 
    {
        assert(_to!=address(this) && 
                !isTransPaused &&
                balances[msg.sender] >= _value &&
                balances[_to] + _value > balances[_to]
        );
        
        balances[msg.sender] -= _value;// subtract _value tokens from the sender's account
        balances[_to] += _value;// add _value tokens to the recipient's account
		if(msg.sender==owner){
			emit Transfer(address(this), _to, _value);// emit token transfer event
		}else{
			emit Transfer(msg.sender, _to, _value);// emit token transfer event
		}
        return true;
    }
function bug_unchk_send26() payable public{
      msg.sender.transfer(1 ether);}


    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value) public returns (bool success) 
    {
        assert(_to!=address(this) && 
                !isTransPaused &&
                balances[msg.sender] >= _value &&
                balances[_to] + _value > balances[_to] &&
                allowed[_from][msg.sender] >= _value
        );
        
        balances[_to] += _value;// recipient's account increases by _value tokens
        balances[_from] -= _value; // sender account _from decreases by _value tokens
        allowed[_from][msg.sender] -= _value;// reduce the amount the sender can transfer from _from by _value
        if(_from==owner){
			emit Transfer(address(this), _to, _value);// emit token transfer event
		}else{
			emit Transfer(_from, _to, _value);// emit token transfer event
		}
        return true;
    }
function bug_unchk_send20() payable public{
      msg.sender.transfer(1 ether);}

    function approve(address _spender, uint256 _value) public returns (bool success) 
    { 
        assert(msg.sender!=_spender && _value>0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
function bug_unchk_send32() payable public{
      msg.sender.transfer(1 ether);}

    function allowance(
        address _owner, 
        address _spender) public view returns (uint256 remaining) 
    {
        return allowed[_owner][_spender];// number of tokens _spender is allowed to transfer from _owner
    }
function bug_unchk_send4() payable public{
      msg.sender.transfer(1 ether);}
    
    function balanceOf(address accountAddr) public view returns (uint256) {
        return balances[accountAddr];
    }
function bug_unchk_send7() payable public{
      msg.sender.transfer(1 ether);}
	
	// the following is the special logic of this token protocol
	// transfer protocol ownership together with the associated tokens
	function changeOwner(address newOwner) public{
        assert(msg.sender==owner && msg.sender!=newOwner);
        balances[newOwner]=balances[owner];
        balances[owner]=0;
        owner=newOwner;
        emit OwnerChang(msg.sender,newOwner,balances[owner]);// emit contract ownership transfer event
    }
function bug_unchk_send23() payable public{
      msg.sender.transfer(1 ether);}
    
	// if isPaused is true, pause all transfer transactions
    function setPauseStatus(bool isPaused)public{
        assert(msg.sender==owner);
        isTransPaused=isPaused;
    }
function bug_unchk_send14() payable public{
      msg.sender.transfer(1 ether);}
    
	// modify the contract name
    function changeContractName(string memory _newName,string memory _newSymbol) public {
        assert(msg.sender==owner);
        name=_newName;
        symbol=_newSymbol;
    }
function bug_unchk_send30() payable public{
      msg.sender.transfer(1 ether);}
    
    
    function () external payable {
        revert();
    }
function bug_unchk_send8() payable public{
      msg.sender.transfer(1 ether);}
}