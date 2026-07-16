pragma solidity ^0.5.0;

contract Context { constructor() internal {}

contract IERC721Receiver { function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4); }

contract ERC165 is IERC165 { bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7; mapping(bytes4 => bool) private _supportedInterfaces; constructor() internal { _registerInterface(_INTERFACE_ID_ERC165); }

contract IERC721Enumerable is IERC721 { function totalSupply() public view returns (uint256); function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId); function tokenByIndex(uint256 index) public view returns (uint256); }

contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable { using SafeMath for uint256; mapping(address => uint256[]) private _ownedTokens; mapping(uint256 => uint256) private _ownedTokensIndex; uint256[] private _allTokens; mapping(uint256 => uint256) private _allTokensIndex; bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63; constructor() public { _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE); }

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata { string private _name; string private _symbol; string private _baseURI; mapping(uint256 => string) private _tokenURIs; bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f; constructor(string memory name, string memory symbol) public { _name = name; _symbol = symbol; _registerInterface(_INTERFACE_ID_ERC721_METADATA); }

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata { constructor(string memory name, string memory symbol) public ERC721Metadata(name, symbol) {}

contract Ownable is Context { address private _owner; event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); constructor() internal { address msgSender = _msgSender(); _owner = msgSender; emit OwnershipTransferred(address(0), msgSender); }

contract ReentrancyGuard { bool private _notEntered; constructor() internal { _notEntered = true; }

contract INXMMaster { address public tokenAddress; address public owner; uint public pauseTime; function masterInitialized() external view returns (bool); function isPause() external view returns (bool check); function isMember(address _add) external view returns (bool); function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress); }

contract TokenData { function lockTokenTimeAfterCoverExp() external returns (uint); }

contract ClaimsData { function actualClaimLength() external view returns (uint); }

contract CoverPurchase { using SafeMath for uint256; uint public distributorFeePercentage = 5; function buyCover( address coveredContractAddress, bytes4 coverCurrency, uint[] calldata coverDetails, uint16 coverPeriod, uint8 _v, bytes32 _r, bytes32 _s ) external payable { uint coverPrice = coverDetails[1]; uint requiredValue = distributorFeePercentage.mul(coverPrice).div(100).add(coverPrice); if (coverCurrency == "ETH") { require(msg.value == requiredValue, "Incorrect value sent"); }

interface IERC721Metadata is IERC721 { function name() external view returns (string memory); function symbol() external view returns (string memory); function tokenURI(uint256 tokenId) external view returns (string memory); }

interface DSValue { function peek() external view returns (bytes32, bool); function read() external view returns (bytes32); }

interface PoolData { struct ApiId { bytes4 typeOf; bytes4 currency; uint id; uint64 dateAdd; uint64 dateUpd; }

interface QuotationData { enum HCIDStatus { NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover }

interface Claims { function getClaimbyIndex(uint _claimId) external view returns ( uint claimId, uint status, int8 finalVerdict, address claimOwner, uint coverId ); function submitClaim(uint coverId) external; }

interface NXMToken { function balanceOf(address owner) external view returns (uint256); function approve(address spender, uint256 value) external returns (bool); }

function _msgSender() internal view returns (address payable) { return msg.sender; } } contract IERC721Receiver { function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4); } contract ERC165 is IERC165 { bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7; mapping(bytes4 => bool) private _supportedInterfaces; constructor() internal { _registerInterface(_INTERFACE_ID_ERC165); }

function supportsInterface(bytes4 interfaceId) external view returns (bool) { return _supportedInterfaces[interfaceId]; } function _registerInterface(bytes4 interfaceId) internal { require(interfaceId != 0xffffffff, "ERC165: invalid interface id"); _supportedInterfaces[interfaceId] = true; }

function isApprovedForAll(address owner, address operator) public view returns (bool) { return _operatorApprovals[owner][operator]; } function transferFrom(address from, address to, uint256 tokenId) public { require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved"); _transferFrom(from, to, tokenId); }

function safeTransferFrom(address from, address to, uint256 tokenId) public { safeTransferFrom(from, to, tokenId, ""); }

function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public { require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved"); _safeTransferFrom(from, to, tokenId, _data); }

function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal { _transferFrom(from, to, tokenId); require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer"); }

function _mint(address to, uint256 tokenId) internal { require(to != address(0), "ERC721: mint to the zero address"); require(!_exists(tokenId), "ERC721: token already minted"); _tokenOwner[tokenId] = to; _ownedTokensCount[to].increment(); emit Transfer(address(0), to, tokenId); }

function _burn(address owner, uint256 tokenId) internal { require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own"); _clearApproval(tokenId); _ownedTokensCount[owner].decrement(); _tokenOwner[tokenId] = address(0); emit Transfer(owner, address(0), tokenId); }

function _burn(uint256 tokenId) internal { _burn(ownerOf(tokenId), tokenId); }

function _transferFrom(address from, address to, uint256 tokenId) internal { require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); require(to != address(0), "ERC721: transfer to the zero address"); _clearApproval(tokenId); _ownedTokensCount[from].decrement(); _ownedTokensCount[to].increment(); _tokenOwner[tokenId] = to; emit Transfer(from, to, tokenId); }

function _clearApproval(uint256 tokenId) internal { if (_tokenApprovals[tokenId] != address(0)) { _tokenApprovals[tokenId] = address(0); emit Approval(ownerOf(tokenId), address(0), tokenId); }

function _burn(address owner, uint256 tokenId) internal { super._burn(owner, tokenId); _removeTokenFromOwnerEnumeration(owner, tokenId); _ownedTokensIndex[tokenId] = 0; _removeTokenFromAllTokensEnumeration(tokenId); }

function _tokensOfOwner(address owner) internal view returns (uint256[] storage) { return _ownedTokens[owner]; } function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private { _ownedTokensIndex[tokenId] = _ownedTokens[to].length; _ownedTokens[to].push(tokenId); }

function _addTokenToAllTokensEnumeration(uint256 tokenId) private { _allTokensIndex[tokenId] = _allTokens.length; _allTokens.push(tokenId); }

function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private { uint256 lastTokenIndex = _ownedTokens[from].length.sub(1); uint256 tokenIndex = _ownedTokensIndex[tokenId]; if (tokenIndex != lastTokenIndex) { uint256 lastTokenId = _ownedTokens[from][lastTokenIndex]; _ownedTokens[from][tokenIndex] = lastTokenId; _ownedTokensIndex[lastTokenId] = tokenIndex; }

function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private { uint256 lastTokenIndex = _allTokens.length.sub(1); uint256 tokenIndex = _allTokensIndex[tokenId]; uint256 lastTokenId = _allTokens[lastTokenIndex]; _allTokens[tokenIndex] = lastTokenId; _allTokensIndex[lastTokenId] = tokenIndex; _allTokens.length--; _allTokensIndex[tokenId] = 0; }

function _setBaseURI(string memory baseURI) internal { _baseURI = baseURI; }

function baseURI() external view returns (string memory) { return _baseURI; } function _burn(address owner, uint256 tokenId) internal { super._burn(owner, tokenId); if (bytes(_tokenURIs[tokenId]).length != 0) { delete _tokenURIs[tokenId]; }

function decrement(Counter storage counter) internal { counter._value = counter._value.sub(1); }

function buyCover( address coveredContractAddress, bytes4 coverCurrency, uint[] calldata coverDetails, uint16 coverPeriod, uint8 _v, bytes32 _r, bytes32 _s ) external payable { uint coverPrice = coverDetails[1]; uint requiredValue = distributorFeePercentage.mul(coverPrice).div(100).add(coverPrice); if (coverCurrency == "ETH") { require(msg.value == requiredValue, "Incorrect value sent"); }

struct ApiId { bytes4 typeOf; bytes4 currency; uint id; uint64 dateAdd; uint64 dateUpd; }

struct Counter { uint256 _value; }

struct Counter { uint256 _value; }

struct ApiId { bytes4 typeOf; bytes4 currency; uint id; uint64 dateAdd; uint64 dateUpd; }

struct CurrencyAssets { address currAddress; uint baseMin; uint varMin; }

struct InvestmentAssets { address currAddress; bool status; uint64 minHoldingPercX100; uint64 maxHoldingPercX100; uint8 decimals; }

struct IARankDetails { bytes4 maxIACurr; uint64 maxRate; bytes4 minIACurr; uint64 minRate; }

struct McrData { uint mcrPercx100; uint mcrEther; uint vFull; uint64 date; }

struct Cover { address payable memberAddress; bytes4 currencyCode; uint sumAssured; uint16 coverPeriod; uint validUntil; address scAddress; uint premiumNXM; }

struct HoldCover { uint holdCoverId; address payable userAddress; address scAddress; bytes4 coverCurr; uint[] coverDetails; uint16 coverPeriod; }

struct Data { INXMMaster nxMaster; }

struct Token { uint expirationTimestamp; bytes4 coverCurrency; uint coverAmount; uint coverPrice; uint coverPriceNXM; uint expireTime; uint generationTime; uint coverId; bool claimInProgress; uint claimId; }