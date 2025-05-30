pragma solidity ^0.5.0;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
pragma solidity 0.5.9;
                                                                                                                 
library SafeMath {
    function add(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
            revert();
        }
        counter_re_ent35 += 1;
    }
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    balanceOf[_from] = balanceOf[_from].sub(_value);                          // Subtract from the targeted balance
            revert();
        }
        not_called_re_ent27 = false;
    }
  event TransferEther(address indexed _from, address indexed _to, uint256 _value);
  mapping(address => uint) balances_re_ent31;
function withdrawFunds_re_ent31 (uint256 _weiToWithdraw) public {
