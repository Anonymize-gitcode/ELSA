pragma solidity ^0.8.0;
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}
contract ZKPVulnerableReentrancy {
    mapping(address => uint256) public balances;
    IVerifier public verifier;
    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
    }
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    function withdraw(uint256 _amount, bytes memory proof, uint256[2] memory input) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        balances[msg.sender] -= _amount;
    }
}