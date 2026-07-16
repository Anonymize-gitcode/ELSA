pragma solidity 0.8.16;

library BeaconChainForks {

    function getCapellaSlot(uint32 sourceChainId) internal pure returns (uint256) {

        if (sourceChainId == 1) {

            return 6209536;
        } else if (sourceChainId == 5) {

            return 5193728;
        } else {

            return 2 ** 256 - 1;
        }
    }

}

struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}

library SSZ {

    function isValidMerkleBranch(bytes32 leaf, uint256 index, bytes32[] memory branch, bytes32 root)
        internal
        pure
        returns (bool)
    {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(leaf, index, branch);
        return root == restoredMerkleRoot;
    }

    function computeDomain(bytes4 forkVersion, bytes32 genesisValidatorsRoot)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(uint256(0x07 << 248))
            | (sha256(abi.encode(forkVersion, genesisValidatorsRoot)) >> 32);
    }

}

interface ILightClient {

    function consistent() external view returns (bool);

    function head() external view returns (uint256);

    function headers(uint256 slot) external view returns (bytes32);

    function executionStateRoots(uint256 slot) external view returns (bytes32);

    function timestamps(uint256 slot) external view returns (uint256);

}

library PairingStep {

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function negate(G1Point memory p) internal pure returns (G1Point memory r) {

        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }
        return G1Point(p.X, q - (p.Y % q));
    }

    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)

            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-add-failed");
    }

    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)

            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-mul-failed");
    }

    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

}

contract StepVerifier {

    using PairingStep for *;

}

library PairingRotate {

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function negate(G1Point memory p) internal pure returns (G1Point memory r) {

        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }
        return G1Point(p.X, q - (p.Y % q));
    }

    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)

            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-add-failed");
    }

    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)

            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-mul-failed");
    }

    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

}

contract RotateVerifier {

    using PairingRotate for *;

}

library Pairing {

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function negate(G1Point memory p) internal pure returns (G1Point memory r) {

        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }
        return G1Point(p.X, q - (p.Y % q));
    }

    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;

        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)

            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-mul-failed");
    }

    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

}

contract OptimizedRotateVerifier {

    using Pairing for *;

}

struct Groth16Proof {
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
}

struct LightClientStep {
    uint256 attestedSlot;
    uint256 finalizedSlot;
    uint256 participation;
    bytes32 finalizedHeaderRoot;
    bytes32 executionStateRoot;
    Groth16Proof proof;
}

struct LightClientRotate {
    LightClientStep step;
    bytes32 syncCommitteeSSZ;
    bytes32 syncCommitteePoseidon;
    Groth16Proof proof;
}

struct LightClientOptimizedRotate {
    LightClientStep step;
    bytes32 syncCommitteeSSZ;
    bytes32 syncCommitteePoseidon;
    Groth16Proof proof;
}

contract LightClient is ILightClient, StepVerifier, RotateVerifier, OptimizedRotateVerifier {

    uint256 public immutable GENESIS_TIME;

    uint256 public immutable SECONDS_PER_SLOT;

    uint32 public immutable SOURCE_CHAIN_ID;

    bool public consistent = true;

    uint256 public head = 0;

    event HeadUpdate(uint256 indexed slot, bytes32 indexed root);

    event SyncCommitteeUpdate(uint256 indexed period, bytes32 indexed root);

    function rotate(LightClientRotate memory update) external {
        LightClientStep memory stepUpdate = update.step;
        bool finalized = processStep(update.step);
        uint256 currentPeriod = getSyncCommitteePeriod(stepUpdate.finalizedSlot);
        uint256 nextPeriod = currentPeriod + 1;

        zkLightClientRotate(update);

        if (finalized) {
            setSyncCommitteePoseidon(nextPeriod, update.syncCommitteePoseidon);
        }
    }

    function getSyncCommitteePeriod(uint256 slot) internal view returns (uint256) {
        return slot / SLOTS_PER_PERIOD;
    }

    function getCurrentSlot() internal view returns (uint256) {
        return (block.timestamp - GENESIS_TIME) / SECONDS_PER_SLOT;
    }

    function setSyncCommitteePoseidon(uint256 period, bytes32 poseidon) internal {
        if (
            syncCommitteePoseidons[period] != bytes32(0)
                && syncCommitteePoseidons[period] != poseidon
        ) {
            consistent = false;
            return;
        }
        syncCommitteePoseidons[period] = poseidon;
        emit SyncCommitteeUpdate(period, poseidon);
    }

        uint256 public totalSupply;

        uint256 public numberOfHolders;

        function calculateShare_DivisionByZero_e1ni() public view returns (uint256) {
            return totalSupply / numberOfHolders;
        }

}
