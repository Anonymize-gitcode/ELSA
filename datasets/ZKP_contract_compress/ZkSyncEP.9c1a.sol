pragma solidity 0.8.28;

struct VerifierParams {
    bytes32 recursionNodeLevelVkHash;
    bytes32 recursionLeafLevelVkHash;
    bytes32 recursionCircuitsSetVksHash;
}

interface IVerifier {

    function verify(uint256[] calldata _publicInputs, uint256[] calldata _proof) external view returns (bool);

    function verificationKeyHash() external view returns (bytes32);

}

contract L1VerifierPlonk is IVerifier {

    uint256 internal constant VK_GATE_SETUP_0_X_SLOT = 0x200 + 0x000;

    uint256 internal constant VK_GATE_SETUP_0_Y_SLOT = 0x200 + 0x020;

    uint256 internal constant VK_GATE_SETUP_1_X_SLOT = 0x200 + 0x040;

    uint256 internal constant VK_GATE_SETUP_1_Y_SLOT = 0x200 + 0x060;

    uint256 internal constant VK_GATE_SETUP_2_X_SLOT = 0x200 + 0x080;

    uint256 internal constant VK_GATE_SETUP_2_Y_SLOT = 0x200 + 0x0a0;

    uint256 internal constant VK_GATE_SETUP_3_X_SLOT = 0x200 + 0x0c0;

    uint256 internal constant VK_GATE_SETUP_3_Y_SLOT = 0x200 + 0x0e0;

    uint256 internal constant VK_GATE_SETUP_4_X_SLOT = 0x200 + 0x100;

    uint256 internal constant VK_GATE_SETUP_4_Y_SLOT = 0x200 + 0x120;

    uint256 internal constant VK_GATE_SETUP_5_X_SLOT = 0x200 + 0x140;

    uint256 internal constant VK_GATE_SETUP_5_Y_SLOT = 0x200 + 0x160;

    uint256 internal constant VK_GATE_SETUP_6_X_SLOT = 0x200 + 0x180;

    uint256 internal constant VK_GATE_SETUP_6_Y_SLOT = 0x200 + 0x1a0;

    uint256 internal constant VK_GATE_SETUP_7_X_SLOT = 0x200 + 0x1c0;

    uint256 internal constant VK_GATE_SETUP_7_Y_SLOT = 0x200 + 0x1e0;

    uint256 internal constant VK_PERMUTATION_0_X_SLOT = 0x200 + 0x280;

    uint256 internal constant VK_PERMUTATION_0_Y_SLOT = 0x200 + 0x2a0;

    uint256 internal constant VK_PERMUTATION_1_X_SLOT = 0x200 + 0x2c0;

    uint256 internal constant VK_PERMUTATION_3_Y_SLOT = 0x200 + 0x360;

    uint256 internal constant VK_LOOKUP_SELECTOR_X_SLOT = 0x200 + 0x380;

    uint256 internal constant VK_LOOKUP_SELECTOR_Y_SLOT = 0x200 + 0x3a0;

    uint256 internal constant VK_LOOKUP_TABLE_0_X_SLOT = 0x200 + 0x3c0;

    uint256 internal constant VK_LOOKUP_TABLE_0_Y_SLOT = 0x200 + 0x3e0;

    uint256 internal constant VK_LOOKUP_TABLE_3_Y_SLOT = 0x200 + 0x4a0;

    uint256 internal constant VK_RECURSIVE_FLAG_SLOT = 0x200 + 0x500;

    uint256 internal constant PROOF_QUOTIENT_POLY_PARTS_0_X_SLOT = 0x200 + 0x520 + 0x1e0;

    uint256 internal constant PROOF_QUOTIENT_POLY_PARTS_3_Y_SLOT = 0x200 + 0x520 + 0x2c0;

    uint256 internal constant PROOF_STATE_POLYS_0_OPENING_AT_Z_SLOT = 0x200 + 0x520 + 0x2e0;

    uint256 internal constant PROOF_GATE_SELECTORS_0_OPENING_AT_Z_SLOT = 0x200 + 0x520 + 0x380;

    uint256 internal constant PROOF_LOOKUP_S_POLY_OPENING_AT_Z_OMEGA_SLOT = 0x200 + 0x520 + 0x420;

    uint256 internal constant PROOF_LOOKUP_T_POLY_OPENING_AT_Z_SLOT = 0x200 + 0x520 + 0x460;

    uint256 internal constant PROOF_LOOKUP_T_POLY_OPENING_AT_Z_OMEGA_SLOT = 0x200 + 0x520 + 0x480;

    uint256 internal constant PROOF_QUOTIENT_POLY_OPENING_AT_Z_SLOT = 0x200 + 0x520 + 0x4e0;

    uint256 internal constant PROOF_LINEARISATION_POLY_OPENING_AT_Z_SLOT = 0x200 + 0x520 + 0x500;

    uint256 internal constant PROOF_OPENING_PROOF_AT_Z_X_SLOT = 0x200 + 0x520 + 0x520;

    uint256 internal constant PROOF_OPENING_PROOF_AT_Z_OMEGA_Y_SLOT = 0x200 + 0x520 + 0x580;

    uint256 internal constant STATE_BETA_PLUS_ONE_SLOT = 0x200 + 0x520 + 0x620 + 0x80 + 0x1a0;

    uint256 internal constant STATE_Z_IN_DOMAIN_SIZE = 0x200 + 0x520 + 0x620 + 0x80 + 0x2a0;

    uint256 internal constant OMEGA = 0x1951441010b2b95a6e47a6075066a50a036f5ba978c050f2821df86636c0facb;

    uint256 internal constant DOMAIN_SIZE = 0x1000000;

    uint256 internal constant Q_MOD = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    uint256 internal constant R_MOD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 internal constant FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 internal constant NON_RESIDUES_0 = 0x05;

    uint256 internal constant NON_RESIDUES_1 = 0x07;

    uint256 internal constant NON_RESIDUES_2 = 0x0a;

    uint256 internal constant G2_ELEMENTS_0_X1 = 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;

    uint256 internal constant G2_ELEMENTS_0_X2 = 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;

    uint256 internal constant G2_ELEMENTS_0_Y1 = 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;

    uint256 internal constant G2_ELEMENTS_0_Y2 = 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

    uint256 internal constant G2_ELEMENTS_1_X1 = 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1;

    function verificationKeyHash() external pure returns (bytes32 vkHash) {
        _loadVerificationKey();

        assembly {
            let start := VK_GATE_SETUP_0_X_SLOT
            let end := VK_RECURSIVE_FLAG_SLOT
            let length := add(sub(end, start), 0x20)

            vkHash := keccak256(start, length)
        }
    }

    function _loadVerificationKey() internal pure virtual {
        assembly {

            mstore(VK_GATE_SETUP_0_X_SLOT, 0x007ab3b6eb38bcb3d387e923a00c9a0e76181545797111e9920869e95413f8b2)
            mstore(VK_GATE_SETUP_0_Y_SLOT, 0x1ccb98df0d44a0f2ea377131d4ebdf771d7cfd9cec5adbdcaf5657cc9c012dd3)
            mstore(VK_GATE_SETUP_1_X_SLOT, 0x04659caf7b05471ba5ba85b1ab62267aa6c456836e625f169f7119d55b9462d2)
            mstore(VK_GATE_SETUP_1_Y_SLOT, 0x0ea63403692148d2ad22189a1e5420076312f4d46e62036a043a6b0b84d5b410)
            mstore(VK_GATE_SETUP_2_X_SLOT, 0x0e6696d09d65fce1e42805be03fca1f14aea247281f688981f925e77d4ce2291)
            mstore(VK_GATE_SETUP_2_Y_SLOT, 0x0228f6cf8fe20c1e07e5b78bf8c41d50e55975a126d22a198d1e56acd4bbb3dd)
            mstore(VK_GATE_SETUP_3_X_SLOT, 0x14685dafe340b1dec5eafcd5e7faddaf24f3781ddc53309cc25d0b42c00541dd)
            mstore(VK_GATE_SETUP_3_Y_SLOT, 0x0e651cff9447cb360198899b80fa23e89ec13bc94ff161729aa841d2b55ea5be)
            mstore(VK_GATE_SETUP_4_X_SLOT, 0x16e9ef76cb68f2750eb0ee72382dd9911a982308d0ab10ef94dada13c382ae73)
            mstore(VK_GATE_SETUP_4_Y_SLOT, 0x22e404bc91350f3bc7daad1d1025113742436983c85eac5ab7b42221a181b81e)
            mstore(VK_GATE_SETUP_5_X_SLOT, 0x0d9b29613037a5025655c82b143d2b7449c98f3aea358307c8529249cc54f3b9)
            mstore(VK_GATE_SETUP_5_Y_SLOT, 0x15b3c4c946ad1babfc4c03ff7c2423fd354af3a9305c499b7fb3aaebe2fee746)
            mstore(VK_GATE_SETUP_6_X_SLOT, 0x29990ff80ff0b5a35a177f8e461ed72b5f80c81af5348bcde0a14d74dbf1b321)
            mstore(VK_GATE_SETUP_6_Y_SLOT, 0x164e998cb7ae3ae5f39b9a96c52464cbe24224fecef541d6a5edd0dd7a1c0c9c)
            mstore(VK_GATE_SETUP_7_X_SLOT, 0x283344a1ab3e55ecfd904d0b8e9f4faea338df5a4ead2fa9a42f0e103da40abc)
            mstore(VK_GATE_SETUP_7_Y_SLOT, 0x223b37b83b9687512d322993edd70e508dd80adb10bcf7321a3cc8a44c269521)

            mstore(VK_GATE_SELECTORS_0_X_SLOT, 0x1f67f0ba5f7e837bc680acb4e612ebd938ad35211aa6e05b96cad19e66b82d2d)
            mstore(VK_GATE_SELECTORS_0_Y_SLOT, 0x2820641a84d2e8298ac2ac42bd4b912c0c37f768ecc83d3a29e7c720763d15a1)
            mstore(VK_GATE_SELECTORS_1_X_SLOT, 0x0353257957562270292a17860ca8e8827703f828f440ee004848b1e23fdf9de2)
            mstore(VK_GATE_SELECTORS_1_Y_SLOT, 0x305f4137fee253dff8b2bfe579038e8f25d5bd217865072af5d89fc8800ada24)

            mstore(VK_PERMUTATION_0_X_SLOT, 0x13a600154b369ff3237706d00948e465ee1c32c7a6d3e18bccd9c4a15910f2e5)
            mstore(VK_PERMUTATION_0_Y_SLOT, 0x138aa24fbf4cdddc75114811b3d59040394c218ecef3eb46ef9bd646f7e53776)
            mstore(VK_PERMUTATION_1_X_SLOT, 0x277fff1f80c409357e2d251d79f6e3fd2164b755ce69cfd72de5c690289df662)
            mstore(VK_PERMUTATION_1_Y_SLOT, 0x25235588e28c70eea3e35531c80deac25cd9b53ea3f98993f120108bc7abf670)
            mstore(VK_PERMUTATION_2_X_SLOT, 0x0990e07a9b001048b947d0e5bd6157214c7359b771f01bf52bd771ba563a900e)
            mstore(VK_PERMUTATION_2_Y_SLOT, 0x05e5fb090dd40914c8606d875e301167ae3047d684a02b44d9d36f1eaf43d0b4)
            mstore(VK_PERMUTATION_3_X_SLOT, 0x1d4656690b33299db5631401a282afab3e16c78ee2c9ad9efea628171dcbc6bc)
            mstore(VK_PERMUTATION_3_Y_SLOT, 0x0ebda2ebe582f601f813ec1e3970d13ef1500c742a85cce9b7f190f333de03b0)

            mstore(VK_LOOKUP_TABLE_0_X_SLOT, 0x2c513ed74d9d57a5ec901e074032741036353a2c4513422e96e7b53b302d765b)
            mstore(VK_LOOKUP_TABLE_0_Y_SLOT, 0x04dd964427e430f16004076d708c0cb21e225056cc1d57418cfbd3d472981468)
            mstore(VK_LOOKUP_TABLE_1_X_SLOT, 0x1ea83e5e65c6f8068f4677e2911678cf329b28259642a32db1f14b8347828aac)
            mstore(VK_LOOKUP_TABLE_1_Y_SLOT, 0x1d22bc884a2da4962a893ba8de13f57aaeb785ed52c5e686994839cab8f7475d)
            mstore(VK_LOOKUP_TABLE_2_X_SLOT, 0x0b2e7212d0d9cff26d0bdf3d79b2cac029a25dfeb1cafdf49e2349d7db348d89)
            mstore(VK_LOOKUP_TABLE_2_Y_SLOT, 0x1301f9b252419ea240eb67fda720ca0b16d92364027285f95e9b1349490fa283)
            mstore(VK_LOOKUP_TABLE_3_X_SLOT, 0x02f7b99fdfa5b418548c2d777785820e02383cfc87e7085e280a375a358153bf)
            mstore(VK_LOOKUP_TABLE_3_Y_SLOT, 0x09d004fe08dc4d19c382df36fad22ef676185663543703e6a4b40203e50fd8a6)

            mstore(VK_LOOKUP_SELECTOR_X_SLOT, 0x2f4d347c7fb61daaadfff881e24f4b5dcfdc0d70a95bcb148168b90ef93e0007)
            mstore(VK_LOOKUP_SELECTOR_Y_SLOT, 0x2322632465ba8e28cd0a4befd813ea85a972f4f6fa8e8603cf5d062dbcb14065)

            mstore(VK_LOOKUP_TABLE_TYPE_X_SLOT, 0x1e3c9fc98c118e4bc34f1f93d214a5d86898e980c40d8e2c180c6ada377a7467)
            mstore(VK_LOOKUP_TABLE_TYPE_Y_SLOT, 0x2260a13535c35a15c173f5e5797d4b675b55d164a9995bfb7624971324bd84a8)

            mstore(VK_RECURSIVE_FLAG_SLOT, 0)
        }
    }

        uint256 public totalFunds = 1000;

        function removeFunds_UnderflowWithLargeSubtraction_nbq8(uint256 funds) public {
            require(funds <= totalFunds, "Insufficient funds");
            totalFunds -= funds;
        }

        uint256 public rewardRate = 2**128;

        function calculateReward_MultiplicationOverflow_eoyb(uint256 stakedAmount) public view returns (uint256) {
            return stakedAmount * rewardRate;
        }

}
