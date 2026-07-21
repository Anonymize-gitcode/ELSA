// Original Contract File: 0x11c26446b5ce3b895ef6a9a594cf9df6e8badbd7.sol
// Injected vulnerability: Incorrect Constructor Name(line 46-48)
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
function adapterType() external pure returns (string memory);
function tokenType() external pure returns (string memory);
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
address internal constant THREE_CRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
address internal constant RENBTC_CRV = 0x49849C98ae39Fff122806C06791Fa73784FB3675;
address internal constant SBTC_CRV = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
address internal constant HBTC_CRV = 0xb19059ebb43466C323583928285a49f558E572Fd;
address internal constant HUSD_CRV = 0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858;
address internal constant USDK_CRV = 0x97E2768e8E73511cA874545DC5Ff8067eB19B787;
address internal constant USDN_CRV = 0x4f3E8F405CF5aFC05D68142F3783bDfE13811522;
address internal constant C_GAUGE = 0x7ca5b0a2910B33e9759DC7dDB0413949071D7575;
address internal constant Y_GAUGE = 0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1;
address internal constant B_GAUGE = 0x69Fb7c45726cfE2baDeE8317005d3F94bE838840;
address internal constant S_GAUGE = 0xA90996896660DEcC6E997655E065b23788857849;
address internal constant P_GAUGE = 0x64E3C23bfc40722d3B649844055F1D51c1ac041d;
address internal constant THREE_GAUGE = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;
address internal constant RENBTC_GAUGE = 0xB1F2cdeC61db658F091671F5f199635aEF202CAC;
address internal constant SBTC_GAUGE = 0x705350c4BcD35c9441419DdD5d2f097d7a55410F;
address internal constant HBTC_GAUGE = 0x4c18E409Dc8619bFb6a1cB56D114C3f592E0aE79;
address internal constant HUSD_GAUGE = 0x2db0E83599a91b508Ac268a6197b8B14F5e72840;
address internal constant USDK_GAUGE = 0xC2b1DF84112619D190193E48148000e3990Bf627;
address internal constant USDN_GAUGE = 0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4;

    function CurveStakingAdapterX() public {
        // SWC-118: Incorrect constructor name (should be CurveStakingAdapter)
    }

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
} else if (token == THREE_CRV) {
return ERC20(THREE_GAUGE).balanceOf(account);
} else if (token == RENBTC_CRV) {
return ERC20(RENBTC_GAUGE).balanceOf(account);
} else if (token == SBTC_CRV) {
return ERC20(SBTC_GAUGE).balanceOf(account);
} else if (token == HBTC_CRV) {
return ERC20(HBTC_GAUGE).balanceOf(account);
} else if (token == HUSD_CRV) {
return ERC20(HUSD_GAUGE).balanceOf(account);
} else if (token == USDK_CRV) {
return ERC20(USDK_GAUGE).balanceOf(account);
} else if (token == USDN_CRV) {
return ERC20(USDN_GAUGE).balanceOf(account);
} else {
return 0;
}
}
}