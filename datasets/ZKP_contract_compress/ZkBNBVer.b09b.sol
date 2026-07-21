pragma solidity ^0.7.6;

contract ZkBNBVerifier {

    function initialize(bytes calldata) external {}

    function upgrade(bytes calldata upgradeParameters) external {}

    function ScalarField()
    public pure returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function NegateY(uint256 Y)
    internal pure returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }

    function prepareBatches(
        uint256[14] memory in_vk,
        uint256[] memory vk_gammaABC,
        uint256[] memory inputAccumulators
    ) internal view returns (
        uint256[4] memory finalVksAlphaX
    ) {

        uint256[4] memory add_input;
        uint256[3] memory mul_input;
        bool success;

        for (uint256 i = 0; i < inputAccumulators.length; i++) {
            mul_input[0] = vk_gammaABC[2 * i];
            mul_input[1] = vk_gammaABC[2 * i + 1];
            mul_input[2] = inputAccumulators[i];

            assembly {

                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            require(success, "Failed to call a precompile for G1 multiplication for input accumulator");

            assembly {

                success := staticcall(sub(gas(), 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            require(success, "Failed to call a precompile for G1 addition for input accumulator");
        }

        finalVksAlphaX[2] = add_input[0];
        finalVksAlphaX[3] = add_input[1];

        uint256[3] memory finalVKalpha;
        finalVKalpha[0] = in_vk[0];
        finalVKalpha[1] = in_vk[1];
        finalVKalpha[2] = inputAccumulators[0];

        assembly {

            success := staticcall(sub(gas(), 2000), 7, finalVKalpha, 0x60, finalVKalpha, 0x40)
        }
        require(success, "Failed to call a precompile for G1 multiplication");
        finalVksAlphaX[0] = finalVKalpha[0];
        finalVksAlphaX[1] = finalVKalpha[1];
    }

    function ic(uint16 block_size) internal pure returns (uint256[] memory gammaABC) {
        if (block_size == 10) {
            gammaABC = new uint256[](8);
            gammaABC[0] = 8201369202054443273161352812996788629155562700528266274348296041642706571631;
            gammaABC[1] = 6705069514728377937422922596604733260444118164729539117716936410745104437695;
            gammaABC[2] = 10707112491194354999264117347635093128387743560803030610022186268454750745921;
            gammaABC[3] = 4915593215140314804562838650643865486391880701539040975746796538061655983515;
            gammaABC[4] = 2073776960343565601332203610327290095347112407516998900009248562560006865473;
            gammaABC[5] = 876173957206826640320824035469636593478781416443386885736344530565787463310;
            gammaABC[6] = 1086733585142054103459149368338483707396009842782068195614865140478460139124;
            gammaABC[7] = 10873808184081766259733927992073224569335741342307194837178213627709010954501;
            return gammaABC;
        } else if (block_size == 1) {
            gammaABC = new uint256[](8);
            gammaABC[0] = 21648086320477345269440034215913835575821298880962856772767754547717742072537;
            gammaABC[1] = 10331213789966296900656101182999274177923825342926217382809974831825802553396;
            gammaABC[2] = 893463785033116972812662594787025335954033076562119613379565367251071896797;
            gammaABC[3] = 11408727999034443630757576894043798537063628530950165640959426887313913219231;
            gammaABC[4] = 10809982183898768757181206340165226401525978271645941108290264338729841616104;
            gammaABC[5] = 8476420811200759626438668116136817738800770684488594223172401850171661757102;
            gammaABC[6] = 1971389536690614652552554244229852425470105053672340435185763862480680798324;
            gammaABC[7] = 17584674328240635644445713066029797285549600910637102125415558920351338780219;
            return gammaABC;
        } else {
            revert("u");
        }
    }

    function getProofEntropy(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs,
        uint proofNumber
    )
    internal pure returns (uint256)
    {

        return uint256(
            keccak256(
                abi.encodePacked(
                    in_proof[proofNumber * 8 + 0], in_proof[proofNumber * 8 + 1], in_proof[proofNumber * 8 + 2], in_proof[proofNumber * 8 + 3],
                    in_proof[proofNumber * 8 + 4], in_proof[proofNumber * 8 + 5], in_proof[proofNumber * 8 + 6], in_proof[proofNumber * 8 + 7],
                    proof_inputs[proofNumber]
                )
            )
        ) >> 3;
    }

    function verifyBatchProofs(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs,
        uint256 num_proofs,
        uint16 block_size
    )
    public
    view
    returns (bool success)
    {
        if (num_proofs == 1) {
            return verifyProof(in_proof, proof_inputs, block_size);
        }
        uint256[14] memory in_vk = verifyingKey(block_size);
        uint256[] memory vk_gammaABC = ic(block_size);
        require(in_proof.length == 8 * num_proofs, "Invalid proofs length for a batch");
        require(proof_inputs.length % num_proofs == 0, "Invalid inputs length for a batch");
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length / num_proofs, "Mismatching number of inputs for verifying key");

        uint256[] memory proofsAandC;
        uint256[] memory inputAccumulators;
        (proofsAandC, inputAccumulators) = accumulate(in_proof, proof_inputs, num_proofs);

        uint256[4] memory finalVksAlphaX = prepareBatches(in_vk, vk_gammaABC, inputAccumulators);

        uint256[] memory inputs = new uint256[](6 * num_proofs + 18);

        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            inputs[proofNumber * 6] = proofsAandC[proofNumber * 2];
            inputs[proofNumber * 6 + 1] = proofsAandC[proofNumber * 2 + 1];
            inputs[proofNumber * 6 + 2] = in_proof[proofNumber * 8 + 2];
            inputs[proofNumber * 6 + 3] = in_proof[proofNumber * 8 + 3];
            inputs[proofNumber * 6 + 4] = in_proof[proofNumber * 8 + 4];
            inputs[proofNumber * 6 + 5] = in_proof[proofNumber * 8 + 5];
        }

        inputs[num_proofs * 6] = finalVksAlphaX[0];
        inputs[num_proofs * 6 + 1] = NegateY(finalVksAlphaX[1]);
        inputs[num_proofs * 6 + 2] = in_vk[2];
        inputs[num_proofs * 6 + 3] = in_vk[3];
        inputs[num_proofs * 6 + 4] = in_vk[4];
        inputs[num_proofs * 6 + 5] = in_vk[5];

        inputs[num_proofs * 6 + 6] = finalVksAlphaX[2];
        inputs[num_proofs * 6 + 7] = NegateY(finalVksAlphaX[3]);
        inputs[num_proofs * 6 + 8] = in_vk[6];
        inputs[num_proofs * 6 + 9] = in_vk[7];
        inputs[num_proofs * 6 + 10] = in_vk[8];
        inputs[num_proofs * 6 + 11] = in_vk[9];

        inputs[num_proofs * 6 + 12] = proofsAandC[num_proofs * 2];
        inputs[num_proofs * 6 + 13] = NegateY(proofsAandC[num_proofs * 2 + 1]);
        inputs[num_proofs * 6 + 14] = in_vk[10];
        inputs[num_proofs * 6 + 15] = in_vk[11];
        inputs[num_proofs * 6 + 16] = in_vk[12];
        inputs[num_proofs * 6 + 17] = in_vk[13];

        uint256 inputsLength = inputs.length * 32;
        uint[1] memory out;
        require(inputsLength % 192 == 0, "Inputs length should be multiple of 192 bytes");

        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(inputs, 0x20), inputsLength, out, 0x20)
        }
        require(success, "Failed to call pairings functions");
        return out[0] == 1;
    }

    function verifyProof(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs,
        uint16 block_size)
    public
    view
    returns (bool)
    {
        uint256[14] memory in_vk = verifyingKey(block_size);
        uint256[] memory vk_gammaABC = ic(block_size);
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length);
        require(in_proof.length == 8);

        uint256[3] memory mul_input;
        uint256[4] memory add_input;
        bool success;
        uint m = 2;

        add_input[0] = vk_gammaABC[0];
        add_input[1] = vk_gammaABC[1];

        uint256 q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

        for (uint i = 0; i < proof_inputs.length; i++) {

            mul_input[0] = vk_gammaABC[m++];
            mul_input[1] = vk_gammaABC[m++];
            mul_input[2] = proof_inputs[i];

            assembly {

                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
            }
            require(success);

            assembly {

                success := staticcall(sub(gas(), 2000), 6, add_input, 0xc0, add_input, 0x60)
            }
            require(success);
        }

        uint[24] memory input = [

            in_proof[0], in_proof[1],
            in_proof[2], in_proof[3], in_proof[4], in_proof[5],

            in_vk[0], NegateY(in_vk[1]),
            in_vk[2], in_vk[3], in_vk[4], in_vk[5],

            add_input[0], NegateY(add_input[1]),
            in_vk[6], in_vk[7], in_vk[8], in_vk[9],

            in_proof[6], NegateY(in_proof[7]),
            in_vk[10], in_vk[11], in_vk[12], in_vk[13]
        ];

        uint[1] memory out;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 768, out, 0x20)
        }
        require(success);
        return out[0] == 1;
    }

    mapping(address => uint256) public donations;

    function donate_ReentrancyInDonate_tlrj() external payable {
        donations[msg.sender] += msg.value;
    }

    function withdraw_ReentrancyInDonate_tlrj() external {
        uint256 amount = donations[msg.sender];
        if (amount > 0) {
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
            donations[msg.sender] = 0;
        }
    }

}
