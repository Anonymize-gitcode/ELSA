pragma solidity ^0.5.0;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
    
contract owned {
  bool not_called_re_ent34 = true;
function bug_re_ent34() public{
        require(not_called_re_ent34);
contract AGR is ERC20, ERC20Detailed, ERC20Burnable {
  constructor() ERC20Detailed('Aggregion Token', 'AGR', 4) public {
        super._mint(msg.sender, 30000000000000);
  }
bool not_called_re_ent13 = true;
function bug_re_ent13() public{
        require(not_called_re_ent13);
pragma solidity ^0.5.00;
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
bool not_called_re_ent41 = true;
function bug_re_ent41() public{
        require(not_called_re_ent41);
