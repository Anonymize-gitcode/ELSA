pragma solidity 0.8.0;

contract FflonkVerifier {

    function verifyProof(bytes32[24] calldata proof, uint256[1] calldata pubSignals) public view returns (bool) {
        assembly {

            function inverseArray(pMem) {

                let pAux := mload(0x40)
                let acc := mload(add(pMem,pZhInv))
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, pDenH1)), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, pDenH2)), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, pLiS0Inv)), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 32))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 64))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 96))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 128))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 160))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 192))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 224))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, pLiS1Inv)), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS1Inv, 32))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS1Inv, 64))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS1Inv, 96))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, pLiS2Inv)), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 32))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 64))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 96))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 128))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 160))), q)
                mstore(pAux, acc)

                pAux := add(pAux, 32)
                acc := mulmod(acc, mload(add(pMem, pEval_l1)), q)
                mstore(pAux, acc)

                let inv := calldataload(pEval_inv)

                if iszero(eq(1, mulmod(acc, inv, q))) {
                    mstore(0, 0)
                    return(0,0x20)
                }

                acc := inv

                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, pEval_l1)), q)
                mstore(add(pMem, pEval_l1), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 160))), q)
                mstore(add(pMem, add(pLiS2Inv, 160)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 128))), q)
                mstore(add(pMem, add(pLiS2Inv, 128)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 96))), q)
                mstore(add(pMem, add(pLiS2Inv, 96)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 64))), q)
                mstore(add(pMem, add(pLiS2Inv, 64)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS2Inv, 32))), q)
                mstore(add(pMem, add(pLiS2Inv, 32)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, pLiS2Inv)), q)
                mstore(add(pMem, pLiS2Inv), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS1Inv, 96))), q)
                mstore(add(pMem, add(pLiS1Inv, 96)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS1Inv, 64))), q)
                mstore(add(pMem, add(pLiS1Inv, 64)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS1Inv, 32))), q)
                mstore(add(pMem, add(pLiS1Inv, 32)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, pLiS1Inv)), q)
                mstore(add(pMem, pLiS1Inv), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 224))), q)
                mstore(add(pMem, add(pLiS0Inv, 224)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 192))), q)
                mstore(add(pMem, add(pLiS0Inv, 192)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 160))), q)
                mstore(add(pMem, add(pLiS0Inv, 160)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 128))), q)
                mstore(add(pMem, add(pLiS0Inv, 128)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 96))), q)
                mstore(add(pMem, add(pLiS0Inv, 96)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 64))), q)
                mstore(add(pMem, add(pLiS0Inv, 64)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, add(pLiS0Inv, 32))), q)
                mstore(add(pMem, add(pLiS0Inv, 32)), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, pLiS0Inv)), q)
                mstore(add(pMem, pLiS0Inv), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, pDenH2)), q)
                mstore(add(pMem, pDenH2), inv)
                pAux := sub(pAux, 32)
                inv := mulmod(acc, mload(pAux), q)
                acc := mulmod(acc, mload(add(pMem, pDenH1)), q)
                mstore(add(pMem, pDenH1), inv)

                mstore(add(pMem, pZhInv), acc)
            }

            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPointBelongsToBN128Curve(p) {
                let x := calldataload(p)
                let y := calldataload(add(p, 32))

                let x3_3 := addmod(mulmod(x, mulmod(x, x, qf), qf), 3, qf)
                let y2 := mulmod(y, y, qf)

                if iszero(eq(x3_3, y2)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkInput() {

                checkPointBelongsToBN128Curve(pC1)
                checkPointBelongsToBN128Curve(pC2)
                checkPointBelongsToBN128Curve(pW1)
                checkPointBelongsToBN128Curve(pW2)

                checkField(calldataload(pEval_ql))
                checkField(calldataload(pEval_qr))
                checkField(calldataload(pEval_qm))
                checkField(calldataload(pEval_qo))
                checkField(calldataload(pEval_qc))
                checkField(calldataload(pEval_s1))
                checkField(calldataload(pEval_s2))
                checkField(calldataload(pEval_s3))
                checkField(calldataload(pEval_a))
                checkField(calldataload(pEval_b))
                checkField(calldataload(pEval_c))
                checkField(calldataload(pEval_z))
                checkField(calldataload(pEval_zw))
                checkField(calldataload(pEval_t1w))
                checkField(calldataload(pEval_t2w))
                checkField(calldataload(pEval_inv))

            }

            function computeChallenges(pMem, pPublic) {

                mstore(add(pMem, 1920 ), C0x)
                mstore(add(pMem, 1952 ), C0y)

                mstore(add(pMem, 1984), calldataload(pPublic))

                mstore(add(pMem, 2016 ),  calldataload(pC1))
                mstore(add(pMem, 2048 ),  calldata