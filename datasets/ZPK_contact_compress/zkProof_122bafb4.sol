    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            require(success, "Transfer failed");
        }
        
}
library Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function withdrawFixedAmount_UnprotectedFixedAmountWithdraw_la43(uint amount) public {
        (bool success, ) = msg.sender.call{value: amount}("");
        return _decimals;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
