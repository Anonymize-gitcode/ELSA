    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}
contract ERC721 {
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    event Abortion(address owner, uint256 matronId, uint256 sireId);
    uint256 public autoBirthFee = 2 finney;
    uint256 public pregnantPandas;
    mapping(uint256 => address) childOwner;
    function setGeneScienceAddress(address _address) external onlyCEO {
    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
pragma solidity ^0.4.24;
contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
