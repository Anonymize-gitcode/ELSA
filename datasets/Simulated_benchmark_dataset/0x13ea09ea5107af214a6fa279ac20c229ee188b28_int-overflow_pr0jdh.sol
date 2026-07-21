// Original Contract File: 0x13ea09ea5107af214a6fa279ac20c229ee188b28.sol
// Injected vulnerability: Integer Overflow and Underflow(line 5-8)
pragma solidity 0.5.17;
contract InterestRateModel {
bool public constant isInterestRateModel = true;

    function unsafeAdd(uint a, uint b) public returns (uint) {
        // SWC-101: No overflow check
        return a + b;
    }

function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);
function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);
}
library SafeMath {
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
require(c >= a, "SafeMath: addition overflow");
return c;
}
function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
uint256 c = a + b;
require(c >= a, errorMessage);
return c;
}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
return sub(a, b, "SafeMath: subtraction underflow");
}
function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b <= a, errorMessage);
uint256 c = a - b;
return c;
}
function mul(uint256 a, uint256 b) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
require(c / a == b, "SafeMath: multiplication overflow");
return c;
}
function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
if (a == 0) {
return 0;
}
uint256 c = a * b;
require(c / a == b, errorMessage);
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
contract WhitePaperInterestRateModel is InterestRateModel {
using SafeMath for uint;
event NewInterestParams(uint baseRatePerBlock, uint multiplierPerBlock);
uint public constant blocksPerYear = 2102400;
uint public multiplierPerBlock;
uint public baseRatePerBlock;
constructor(uint baseRatePerYear, uint multiplierPerYear) public {
baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
multiplierPerBlock = multiplierPerYear.div(blocksPerYear);
emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
}
function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns (uint) {
if (borrows == 0) {
return 0;
}
return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
}
function getBorrowRate(uint cash, uint borrows, uint reserves) public view returns (uint) {
uint ur = utilizationRate(cash, borrows, reserves);
return ur.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
}
function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) public view returns (uint) {
uint oneMinusReserveFactor = uint(1e18).sub(reserveFactorMantissa);
uint borrowRate = getBorrowRate(cash, borrows, reserves);
uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
}
}