pragma solidity ^0.5.11; //compiles with 0.5.0 and above
library SafeMath {	//contract --> library : compiler version up
    function add(uint a, uint b) internal pure returns (uint c) {	//public -> internal : compiler version up
        c = a + b;
        require(c >= a);
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
