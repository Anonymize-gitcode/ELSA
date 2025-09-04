pragma solidity ^0.8.0;
interface IVerifier {
    function verifyProof(bytes memory proof, uint256[2] memory input) external view returns (bool);
}
contract ZKPMemberBenefit {
    IVerifier public verifier;
    mapping(address => uint256) public memberBenefits; // Stores benefit amounts for each member
    mapping(address => bool) public isMember;  // Tracks whether an address is a registered member
    uint256 public totalBenefitPool; // The total benefit pool amount
    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
        totalBenefitPool = 200 ether; // Initialize benefit pool with 200 ETH
    }
    function donateToBenefitPool() public payable {
        require(msg.value > 0, "Must donate some Ether");
        totalBenefitPool += msg.value;
    }
    function setMemberBenefit(address _member, uint256 _amount) public {
        require(isMember[_member], "Address is not a registered member");
        require(_amount <= totalBenefitPool, "Insufficient funds in benefit pool");
        memberBenefits[_member] = _amount;
    }
    function registerMember(address _member) public {
        isMember[_member] = true;
    }
    function claimMemberBenefit(uint256 amount, bytes memory proof, uint256[2] memory input) public {
        require(isMember[msg.sender], "User is not a member");
        require(memberBenefits[msg.sender] >= amount, "Insufficient benefit balance");
        bool isValid = verifier.verifyProof(proof, input);
        require(isValid, "Invalid ZKP proof");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Benefit transfer failed");
        memberBenefits[msg.sender] -= amount;
        totalBenefitPool -= amount;
    }
    function getMemberBenefitBalance() public view returns (uint256) {
        return memberBenefits[msg.sender];
    }
}