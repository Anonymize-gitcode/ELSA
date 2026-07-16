pragma solidity ^0.5.11;
contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
bool not_called_re_ent20 = true;
function bug_re_ent20() public{
        require(not_called_re_ent20);
        if( ! (msg.sender.send(1 ether) ) ){
pragma solidity ^0.5.11; //compiles with 0.5.0 and above
library SafeMath {	//contract --> library : compiler version up
    function add(uint a, uint b) internal pure returns (uint c) {	//public -> internal : compiler version up
        c = a + b;
        require(c >= a);
pragma solidity ^0.5.0;
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
pragma solidity ^0.5.11;
contract ERC20Interface {
    function totalSupply() public view returns (uint);
function sendto_txorigin17(address payable receiver, uint amount,address owner_txorigin17) public {
	require (tx.origin == owner_txorigin17);
	receiver.transfer(amount);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {	//public -> internal : compiler version up
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {	//public -> internal : compiler version up
