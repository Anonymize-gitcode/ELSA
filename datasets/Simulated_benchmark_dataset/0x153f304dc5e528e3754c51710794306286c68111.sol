pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

interface ERC20 {

function approve(address, uint256) external returns (bool);

function transfer(address, uint256) external returns (bool);

function transferFrom(address, address, uint256) external returns (bool);

function name() external view returns (string memory);

function symbol() external view returns (string memory);

function decimals() external view returns (uint8);

function totalSupply() external view returns (uint256);

function balanceOf(address) external view returns (uint256);

}

interface ProtocolAdapter {



/**

* @dev MUST return "Asset" or "Debt".

* SHOULD be implemented by the public constant state variable.

*/

function adapterType() external pure returns (string memory);



/**

* @dev MUST return token type (default is "ERC20").

* SHOULD be implemented by the public constant state variable.

*/

function tokenType() external pure returns (string memory);



/**

* @dev MUST return amount of the given token locked on the protocol by the given account.

*/

function getBalance(address token, address account) external view returns (uint256);

}

contract CurveStakingAdapter is ProtocolAdapter {



string public constant override adapterType = "Asset";



string public constant override tokenType = "ERC20";



address internal constant C_CRV = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;

address internal constant Y_CRV = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;

address internal constant B_CRV = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;

address internal constant S_CRV = 0xC25a3A3b969415c80451098fa907EC722572917F;

address internal constant P_CRV = 0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8;

address internal constant REN_CRV = 0x49849C98ae39Fff122806C06791Fa73784FB3675;

address internal constant SBTC_CRV = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;



address internal constant C_GAUGE = 0x7ca5b0a2910B33e9759DC7dDB0413949071D7575;

address internal constant Y_GAUGE = 0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1;

address internal constant B_GAUGE = 0x69Fb7c45726cfE2baDeE8317005d3F94bE838840;

address internal constant S_GAUGE = 0xA90996896660DEcC6E997655E065b23788857849;

address internal constant P_GAUGE = 0x64E3C23bfc40722d3B649844055F1D51c1ac041d;

address internal constant REN_GAUGE = 0xB1F2cdeC61db658F091671F5f199635aEF202CAC;

address internal constant SBTC_GAUGE = 0x705350c4BcD35c9441419DdD5d2f097d7a55410F;



/**

* @return Amount of staked LP tokens for a given account.

* @dev Implementation of ProtocolAdapter interface function.

*/

function getBalance(address token, address account) external view override returns (uint256) {

if (token == C_CRV) {

return ERC20(C_GAUGE).balanceOf(account);

} else if (token == Y_CRV) {

return ERC20(Y_GAUGE).balanceOf(account);

} else if (token == B_CRV) {

return ERC20(B_GAUGE).balanceOf(account);

} else if (token == S_CRV) {

return ERC20(S_GAUGE).balanceOf(account);

} else if (token == P_CRV) {

return ERC20(P_GAUGE).balanceOf(account);

} else if (token == REN_CRV) {

return ERC20(REN_GAUGE).balanceOf(account);

} else if (token == SBTC_CRV) {

return ERC20(SBTC_GAUGE).balanceOf(account);

} else {

return 0;

}

}

}