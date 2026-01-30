pragma solidity ^0.8.0;
contract ZKPVerification {
    address public owner;
    mapping(address => uint256) public balances;
    constructor() {
        owner = msg.sender;
    }
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    function zkVerify(bytes32 publicInput, bytes32 proofHash) public pure returns (bool) {
        return keccak256(abi.encodePacked(publicInput)) == proofHash;
    }
    function transferWithZKP(
        address _recipient, 
        uint256 _amount, 
        bytes32 publicInput, 
        bytes32 proofHash
    ) public {
        require(zkVerify(publicInput, proofHash), "ZKP validation failed");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }
    function withdrawWithoutProtection(address _recipient, uint256 _amount) public {
        require(balances[_recipient] >= _amount, "Insufficient balance");
        balances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Ether transfer failed");
    }
    receive() external payable {}
}