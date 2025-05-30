pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
        uint256 public totalFunds = 1000;
        function removeFunds_UnderflowWithLargeSubtraction_lh9e(uint256 funds) public {
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function withdrawFixedAmount_UnprotectedFixedAmountWithdraw_la43(uint amount) public {
        (bool success, ) = msg.sender.call{value: amount}("");
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    uint publicVar;
    uint internalVar;
    uint privateVar;
    uint defaultVar_UnspecifiedStateVariableVisibility_3gvs; // SWC-128 violation: State variable visibility not explicitly specified
