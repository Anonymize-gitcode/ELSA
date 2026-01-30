pragma solidity ^0.8.0;
interface ITransferVerifier {
    function verifyTransferProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input
    ) external returns (bool);
}
contract ZKPWithTransferAndSWC110 {
    ITransferVerifier public verifier;
    mapping(address => uint256) public balances;
    uint256 public maxTransferAmount = 1000;
    event TransferSuccessful(address indexed sender, address indexed receiver, uint256 amount);
    constructor(address verifierAddress) {
        verifier = ITransferVerifier(verifierAddress);
        balances[msg.sender] = 5000;
    }
    function verifyAndTransfer(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[1] memory input,
        address receiver,
        uint256 amount
    ) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        bool proofValid = verifier.verifyTransferProof(a, b, c, input);
        if (proofValid) {
            balances[msg.sender] -= amount;
            balances[receiver] += amount;
            assert(amount <= maxTransferAmount); 
            emit TransferSuccessful(msg.sender, receiver, amount);
        }
    }
    function getBalance(address account) public view returns (uint256) {
        return balances[account];
    }
}