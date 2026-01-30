pragma solidity ^0.8.0;
contract ZKPReferralSystem {
    address public owner;
    mapping(address => bool) public proofSubmitted;
    mapping(address => uint256) public referralRewards;
    uint256 public totalRewards;
    constructor() {
        owner = msg.sender;
    }
    function submitProof(uint256[2] memory proof, uint256[2] memory input) public {
        require(verifyProof(proof, input), "Invalid zero-knowledge proof");
        require(!proofSubmitted[msg.sender], "Proof already submitted");
        proofSubmitted[msg.sender] = true;
    }
    function verifyProof(uint256[2] memory proof, uint256[2] memory input) internal pure returns (bool) {
        return (proof[0] * proof[1]) == (input[0] * input[1]);
    }
    function claimReferralReward(uint256 amount) public {
        require(proofSubmitted[msg.sender], "Proof not submitted");
        require(amount > 0, "Reward amount must be greater than zero");
        referralRewards[msg.sender] += amount;
        totalRewards += amount;
    }
    
    function withdrawReferralReward(uint256 amount) public {
        require(referralRewards[msg.sender] >= amount, "Insufficient reward balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
        referralRewards[msg.sender] -= amount;
        totalRewards -= amount;
    }
    function getReferralRewardBalance(address referrer) public view returns (uint256) {
        return referralRewards[referrer];
    }
    receive() external payable {}
}