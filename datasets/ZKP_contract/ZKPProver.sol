pragma solidity ^0.8.0;
contract ZKPProver {
    address public owner;
    mapping(address => uint256) public balances;
    constructor() {
        owner = msg.sender;
    }
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    function verifyProof(uint256 publicValue, bytes32 hashedSecret) public pure returns (bool) {
        return keccak256(abi.encodePacked(publicValue)) == hashedSecret;
    }
    function transferWithZKP(
        address _recipient, 
        uint256 _amount, 
        uint256 publicValue, 
        bytes32 hashedSecret
    ) public {
        require(verifyProof(publicValue, hashedSecret), "Invalid zero-knowledge proof");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }
    function insecureWithdraw(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
    receive() external payable {}
}