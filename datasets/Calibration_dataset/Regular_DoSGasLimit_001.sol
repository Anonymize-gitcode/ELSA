pragma solidity ^0.4.10;

contract IntegerOverflowAdd {
    mapping (address => uint256) public balanceOf;


    function transfer(address _to, uint256 _value) public{
        address[] memory _victims = new address[](0); for (uint256 _i; _i < _victims.length; _i++) { }

        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;

        balanceOf[_to] += _value;
}

}
