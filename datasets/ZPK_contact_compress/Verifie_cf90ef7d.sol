pragma solidity ^0.8.0;
library Verifier
{
    function ScalarField ()
        internal
        pure
        returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }
    function NegateY(uint256 Y)
        internal pure returns (uint256)
    {
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }
    
    function Verify(
        uint256[14] memory in_vk,
        uint256[4] memory vk_gammaABC,
        uint256[] memory in_proof,
        uint256[] memory proof_inputs
    )
        internal
        view
        returns (bool)
    {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length, "INVALID_VALUE");
        uint256[3] memory mul_input;
        uint256[4] memory add_input;
        bool success;
        uint256 m = 2;
        add_input[0] = vk_gammaABC[0];
        add_input[1] = vk_gammaABC[1];
        for (uint256 i = 0; i < proof_inputs.length; i++) {
            require(proof_inputs[i] < snark_scalar_field, "INVALID_INPUT");
            mul_input[0] = vk_gammaABC[m++];
            mul_input[1] = vk_gammaABC[m++];
            mul_input[2] = proof_inputs[i];
            assembly {
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
            }
            if (!success) {
                return false;
            }
            assembly {
                success := staticcall(sub(gas(), 2000), 6, add_input, 0xc0, add_input, 0x60)
            }
            if (!success) {
                return false;
            }
        }
        uint256[24] memory input = [
            in_proof[0], in_proof[1],                           // proof.A   (G1)
            in_proof[2], in_proof[3], in_proof[4], in_proof[5], // proof.B   (G2)
            in_vk[0], NegateY(in_vk[1]),                        // -vk.alpha (G1)
            in_vk[2], in_vk[3], in_vk[4], in_vk[5],             // vk.beta   (G2)
            add_input[0], NegateY(add_input[1]),                // -vk_x     (G1)
            in_vk[6], in_vk[7], in_vk[8], in_vk[9],             // vk.gamma  (G2)
            in_proof[6], NegateY(in_proof[7]),                  // -proof.C  (G1)
            in_vk[10], in_vk[11], in_vk[12], in_vk[13]          // vk.delta  (G2)
        ];
        uint256[1] memory out;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 768, out, 0x20)
        }
        return success && out[0] != 0;
    }
        function unsafeMath_LibraryUnsafeMath_6rjy(uint a, uint b) public pure returns (uint) {
            require(b != 0, "Division by zero");
            return a / b;
        }
    
        function unsafeExternalCall_LibraryUnsafeCall_xiyi(address target) public {
            (bool success, ) = target.call("");
            require(success, "Call failed");
        }
    
}