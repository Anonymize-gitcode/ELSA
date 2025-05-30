pragma solidity 0.8.0;
contract ZKPVerifierBase {
    struct ZKPRequest {
        uint64 requestId;
        address validator;
    }
    mapping(uint64 => ZKPRequest) private requests;
    function setZKPRequest(uint64 requestId, ZKPRequest calldata request) internal virtual {
        requests[requestId] = request;
    }
    function getZKPRequest(uint64 requestId) internal view returns (ZKPRequest memory) {
        return requests[requestId];
    }
    function submitZKPResponse(
        uint64 requestId,
        uint256[] memory inputs,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) internal virtual {
    }
    function __ZKPVerifierBase_init(IState state) internal {
    }
        uint256 public counter;
        function decrement_UncheckedSubtraction_rbze(uint256 value) public {
            unchecked {
                counter -= value;  // 使用unchecked，可能发生下溢
            }
        }
        
}
contract Ownable2StepUpgradeable {
    address private _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
    function __Ownable_init(address initialOwner) internal {
        _owner = initialOwner;
    }
}
interface IState {
}
interface ICircuitValidator {
}
contract EmbeddedZKPVerifier is Ownable2StepUpgradeable, ZKPVerifierBase {
    function __EmbeddedZKPVerifier_init(
        address initialOwner,
        IState state
    ) internal {
        __Ownable_init(initialOwner);
        ___EmbeddedZKPVerifier_init_unchained();
        __ZKPVerifierBase_init(state);
    }
    function ___EmbeddedZKPVerifier_init_unchained() internal {}
    function setZKPRequest(
        uint64 requestId,
        ZKPRequest calldata request
    ) internal override {
        ZKPVerifierBase.setZKPRequest(requestId, request);
    }
    function submitZKPResponse(
        uint64 requestId,
        uint256[] memory inputs,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c
    ) internal override {
        ZKPRequest memory request = getZKPRequest(requestId);
        _beforeProofSubmit(requestId, inputs, ICircuitValidator(request.validator));
        ZKPVerifierBase.submitZKPResponse(requestId, inputs, a, b, c);
        _afterProofSubmit(requestId, inputs, ICircuitValidator(request.validator));
    }
    function _beforeProofSubmit(
        uint64 requestId,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal virtual {}
    function _afterProofSubmit(
        uint64 requestId,
        uint256[] memory inputs,
        ICircuitValidator validator
    ) internal virtual {}
}
contract ZKPVerifier is EmbeddedZKPVerifier {
    function initialize(address initialOwner, IState state) external {
        __EmbeddedZKPVerifier_init(initialOwner, state);
    }
}