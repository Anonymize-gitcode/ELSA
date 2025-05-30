pragma solidity ^0.8.0;
contract KeysWithPlonkVerifier {
    uint256 constant VK_TREE_ROOT = 0x18e5b30d2b3c5a791c8e9cbc45ff45d0cf72a5b9df98b3820f42dec2e25b4302;
    uint8 constant VK_MAX_INDEX = 2;
    struct VerificationKey {
        uint256 domain_size;
        uint256 num_inputs;
        uint256 omega;
        uint256[7] gate_setup_commitments;
        uint256[2] gate_selector_commitments;
        uint256[4] copy_permutation_commitments;
        uint256[3] copy_permutation_non_residues;
        uint256[2] g2_x;
    }
    function getVkAggregated(uint32 _proofs) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(4)) { return getVkAggregated4(); }
    }
    function getVkAggregated4() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 8388608;
        vk.num_inputs = 1;
        vk.omega = 0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863;
        vk.gate_setup_commitments[0] = 0x2cf12f7832b5225697a0546bbff09e6f683cb934248153dcd275d07aad865f33;
        vk.gate_setup_commitments[1] = 0x24325822f1120b45d7dbc0856f38eea4e04564be25db340ace1842c2ec425eee;
        vk.gate_setup_commitments[2] = 0x2b045c42175f88a919baddad23f2e8071062ccdb0827ecc3d065ed31ada5362f;
        vk.gate_setup_commitments[3] = 0x03780bf1d281d9826bc604575714a0237fd83fbd4e759707326f4b878456cd4f;
        vk.gate_setup_commitments[4] = 0x02e962e57dd5e2c98f5237d22063d99a93a362660f538eb8c3904f13cfce9b21;
        vk.gate_setup_commitments[5] = 0x06422f605c5a1314c982c719726a103e47cdee8f69d965b9f4e8990405c185c0;
        vk.gate_setup_commitments[6] = 0x0a2d1801286447914e59523170957011914d83e3d41d2cad8659d1ea3987d333;
        vk.gate_selector_commitments[0] = 0x1959ddadc62fc4908393a213b6abfbcbc2f176ccb94fa5b62abf0f59e7b328f0;
        vk.gate_selector_commitments[1] = 0x14b425124626a626f1c636c88ed0256ad7d5903a3f0ae7a76baf59d757202635;
        vk.copy_permutation_commitments[0] = 0x0de480e3b300252122d4ddd21896e626bd9986c3e12d05dbe485f11e1e9dce07;
        vk.copy_permutation_commitments[1] = 0x05dd6ba19c87be1a749994d434c7e039aa8366c1796fb930d5e2aade1fd3ea62;
        vk.copy_permutation_commitments[2] = 0x208fafa47233eb3c655016458d06681fb21ab02fa94de895865e183452b58799;
        vk.copy_permutation_commitments[3] = 0x1327632855252d0ab25e57bd5319e6a4b47fa9ccc7e812e941df6a125d33ef2e;
        vk.copy_permutation_non_residues[0] = 0x0000000000000000000000000000000000000000000000000000000000000005;
        vk.copy_permutation_non_residues[1] = 0x0000000000000000000000000000000000000000000000000000000000000007;
        vk.copy_permutation_non_residues[2] = 0x000000000000000000000000000000000000000000000000000000000000000a;
        vk.g2_x[0] = 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1;
        vk.g2_x[1] = 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0;
    }
}
contract KeysWithPlonkVerifierOld {
    struct VerificationKeyOld {
        uint256 domain_size;
        uint256 num_inputs;
        uint256 omega;
        uint256[6] selector_commitments;
        uint256[1] next_step_selector_commitments;
        uint256[4] permutation_commitments;
        uint256[3] permutation_non_residues;
        uint256[2] g2_x;
    }
    function getVkExit() internal pure returns(VerificationKeyOld memory vk) {
        vk.domain_size = 2097152;
        vk.num_inputs = 1;
        vk.omega = 0x032750f8f3c2493d0828c7285d0258e1bdcaa463f4442a52747b5c96639659bb;
        vk.selector_commitments[0] = 0x056707bb6d8c0ce743f3bc6743551b911a9eb709872234a46fc71b7c3c2f71bc;
        vk.selector_commitments[1] = 0x04301adb36673b362f4b67438100c0c8c0ea4c13bc962b89c9a3425b9ce65f1a;
        vk.selector_commitments[2] = 0x0e209c72488d29c2978dd4e4c1e6d84d036185ff4cfe94a36cab356ec46a5a74;
        vk.selector_commitments[3] = 0x100db92f3abe27e28c87e9ad825b770ba38d74f013070c9b7e9ce5608267ae05;
        vk.selector_commitments[4] = 0x2c3fb4218a616df02901dea9940f97df1d1d6e26430fcd4948d4a46d007abb3b;
        vk.selector_commitments[5] = 0x13de9a5cecac0bace86d7bc0d0a563eeebc0a986a02e811e67a983ce8b82c35b;
        vk.next_step_selector_commitments[0] = 0x01a6af76016c335b1e0fc43dfb767ab6a70c10065bee25ecba7d35885fd94709;
        vk.permutation_commitments[0] = 0x0ffdbc4ce1959ba230baa6046b0b293bd6368c5d9d8506f9e830397c9d87f288;
        vk.permutation_commitments[1] = 0x1932c97baf6a2942ada6721b12dbf14f385a079ff7fac03c1f5b818c1ba1dc70;
        vk.permutation_commitments[2] = 0x202c332882bb6b61045025c5bc6bb636cc36152206b1d749cdebde5874890861;
        vk.permutation_commitments[3] = 0x092840664e05259fb3431aaf516f80f38ebf7c5ac7882c6ce1efcc31692b45aa;
        vk.permutation_non_residues[0] = 0x0000000000000000000000000000000000000000000000000000000000000005;
        vk.permutation_non_residues[1] = 0x0000000000000000000000000000000000000000000000000000000000000007;
        vk.permutation_non_residues[2] = 0x000000000000000000000000000000000000000000000000000000000000000a;
        vk.g2_x[0] = 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1;
        vk.g2_x[1] = 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0;
    }
    enum Status { Active, Inactive }
    Status currentStatus_UnspecifiedEnumVisibility_vuad; // SWC-128 violation: Enum visibility not explicitly specified
    uint constant FEE_PERCENTAGE = 3; 
}