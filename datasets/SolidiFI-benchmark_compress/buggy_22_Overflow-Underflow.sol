    balances_intou10[msg.sender] -= _value;  //bug
    balances_intou10[_to] += _value;  //bug
    return true;
  }
  address public owner;
  constructor() public {
    owner = msg.sender;
  }
function bug_intou20(uint8 p_intou20) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou20;   // overflow bug
pragma solidity 0.5.1;
contract owned {
  function bug_intou24(uint8 p_intou24) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou24;   // overflow bug
}
  address public owner;
    constructor() public {
        owner = msg.sender;
    }
function bug_intou11() public{
    uint8 vundflw =0;
    vundflw = vundflw -10;   // underflow bug
}
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
mapping(address => uint) public lockTime_intou1;
    vundflw1 = vundflw1 + p_intou24;   // overflow bug
}
  address public owner;
    constructor() internal {
        owner = msg.sender;
        owner = 0x800A4B210B920020bE22668d28afd7ddef5c6243
;
    }
function bug_intou20(uint8 p_intou20) public{
    uint8 vundflw1=0;
        _;
    }
    modifier onlyChairman {
        require(msg.sender == chairmanAddress);
        _;
    }
    
    constructor() payable public {
    }
function bug_intou32(uint8 p_intou32) public{
    uint8 vundflw1=0;
    vundflw1 = vundflw1 + p_intou32;   // overflow bug
