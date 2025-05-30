    }
}
contract ERC20 {
    function totalSupply() public view returns (uint256);
mapping(address => uint) balances_intou10;
function transfer_intou10(address _to, uint _value) public returns (bool) {
    require(balances_intou10[msg.sender] - _value >= 0);  //bug
pragma solidity ^0.5.11;
contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
function cash_unchk46(uint roundIndex, uint subpotIndex, address payable winner_unchk46) public{
        uint64 subpot_unchk46 = 3 ether;
        winner_unchk46.send(subpot_unchk46);  //bug
pragma solidity ^0.5.11;
contract ERC20Interface {
    function totalSupply() public view returns (uint);
mapping(address => uint) balances_re_ent17;
function withdrawFunds_re_ent17 (uint256 _weiToWithdraw) public {
        require(balances_re_ent17[msg.sender] >= _weiToWithdraw);
pragma solidity ^0.5.11;
contract ERC20Interface {
    function totalSupply() public view returns (uint);
mapping(address => uint) public lockTime_intou17;
function increaseLockTime_intou17(uint _secondsToIncrease) public {
        lockTime_intou17[msg.sender] += _secondsToIncrease;  //overflow
