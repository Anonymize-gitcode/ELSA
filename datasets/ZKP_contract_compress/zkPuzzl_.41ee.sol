pragma solidity 0.8.0;

contract PlonkVerifier {

    function verifyProof(bytes memory proof, uint[] memory pubSignals) public view returns (bool) {
        assembly {

            function inverse(a, q) -> inv {
                let t := 0
                let newt := 1
                let r := q
                let newr := a
                let quotient
                let aux

                for { } newr { } {
                    quotient := sdiv(r, newr)
                    aux := sub(t, mul(quotient, newt))
                    t:= newt
                    newt:= aux

                    aux := sub(r,mul(quotient, newr))
                    r := newr
                    newr := aux
                }

                if gt(r, 1) { revert(0,0) }
                if slt(t, 0) { t:= add(t, q) }

                inv := t
            }

            function inverseArray(pVals, n) {

                let pAux := mload(0x40)
                let pIn := pVals
                let lastPIn := add(pVals, mul(n, 32))
                let acc := mload(pIn)
                pIn := add(pIn, 32)
                let inv

                for { } lt(pIn, lastPIn) {
                    pAux := add(pAux, 32)
                    pIn := add(pIn, 32)
                }
                {
                    mstore(pAux, acc)
                    acc := mulmod(acc, mload(pIn), q)
                }
                acc := inverse(acc, q)

                pAux := sub(pAux, 32)

                pIn := sub(pIn, 32)
                lastPIn := pVals
                for { } gt(pIn, lastPIn) {
                    pAux := sub(pAux, 32)
                    pIn := sub(pIn, 32)
                }
                {
                    inv := mulmod(acc, mload(pAux), q)
                    acc := mulmod(acc, mload(pIn), q)
                    mstore(pIn, inv)
                }

                mstore(pIn, acc)
            }

            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0,0x20)
                }
            }

            function checkInput(pProof) {
                if iszero(eq(mload(pProof), 800 )) {
                    mstore(0, 0)
                    return(0,0x20)
                }
                checkField(mload(add(pProof, pEval_a)))
                checkField(mload(add(pProof, pEval_b)))
                checkField(mload(add(pProof, pEval_c)))
                checkField(mload(add(pProof, pEval_s1)))
                checkField(mload(add(pProof, pEval_s2)))
                checkField(mload(add(pProof, pEval_zw)))
                checkField(mload(add(pProof, pEval_r)))

            }

            function calculateChallanges(pProof, pMem) {

                let a
                let b

                b := mod(keccak256(add(pProof, pA), 192), q)
                mstore( add(pMem, pBeta), b)
                mstore( add(pMem, pGamma), mod(keccak256(add(pMem, pBeta), 32), q))
                mstore( add(pMem, pAlpha), mod(keccak256(add(pProof, pZ), 64), q))

                a := mod(keccak256(add(pProof, pT1), 192), q)
                mstore( add(pMem, pXi), a)
                mstore( add(pMem, pBetaXi), mulmod(b, a, q))

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                a:= mulmod(a, a, q)

                mstore( add(pMem, pXin), a)
                a:= mod(add(sub(a, 1),q), q)
                mstore( add(pMem, pZh), a)
                mstore( add(pMem, pZhInv), a)

                let v1 := mod(keccak256(add(pProof, pEval_a), 224), q)
                mstore( add(pMem, pV1), v1)
                a := mulmod(v1, v1, q)
                mstore( add(pMem, pV2), a)
                a := mulmod(a, v1, q)
                mstore( add(pMem, pV3), a)
                a := mulmod(a, v1, q)
                mstore( add(pMem, pV4), a)
                a := mulmod(a, v1, q)
                mstore( add(pMem, pV5), a)
                a := mulmod(a, v1, q)
                mstore( add(pMem, pV6), a)

                mstore( add(pMem, pU), mod(keccak256(add(pProof, pWxi), 128), q))
            }

            function calculateLagrange(pMem) {

                let w := 1

                mstore(
                    add(pMem, pEval_l1),
                    mulmod(
                        n,
                        mod(
                            add(
                                sub(
                                    mload(add(pMem, pXi)),
                                    w
                                ),
                                q
                            ),
                            q
                        ),
                        q
                    )
                )

                inverseArray(add(pMem, pZhInv), 2 )

                let zh := mload(add(pMem, pZh))
                w := 1

                mstore(
                    add(pMem, pEval_l1 ),
                    mulmod(
                        mload(add(pMem, pEval_l1 )),
                        zh,
                        q
                    )
                )

            }

            function calculatePl(pMem, pPub) {
                let pl := 0

                pl := mod(
                    add(
                        sub(
                            pl,
                            mulmod(
                                mload(add(pMem, pEval_l1)),
                                mload(add(pPub, 32)),
                                q
                            )
                        ),
                        q
                    ),
                    q
                )

                mstore(add(pMem, pPl), pl)

            }

            function calculateT(pProof, pMem) {
                let t
                let t1
                let t2
                t := addmod(
                    mload(add(pProof, pEval_r)),
                    mload(add(pMem, pPl)),
                    q
                )

                t1 := mulmod(
                    mload(add(pProof, pEval_s1)),
                    mload(add(pMem, pBeta)),
                    q
                )

                t1 := addmod(
                    t1,
                    mload(add(pProof, pEval_a)),
                    q
                )

                t1 := addmod(
                    t1,
                    mload(add(pMem, pGamma)),
                    q
                )

                t2 := mulmod(
                    mload(add(pProof, pEval_s2)),
                    mload(add(pMem, pBeta)),
                    q
                )

                t2 := addmod(
                    t2,
                    mload(add(pProof, pEval_b)),
                    q
                )

                t2 := addmod(
                    t2,
                    mload(add(pMem, pGamma)),
                    q
                )

                t1 := mulmod(t1, t2, q)

                t2 := addmod(
                    mload(add(pProof, pEval_c)),
                    mload(add(pMem, pGamma)),
                    q
                )

                t1 := mulmod(t1, t2, q)
                t1 := mulmod(t1, mload(add(pProof, pEval_zw)), q)
                t1 := mulmod(t1, mload(add(pMem, pAlpha)), q)

                t2 := mulmod(
                    mload(add(pMem, pEval_l1)),
                    mload(add(pMem, pAlpha)),
                    q
                )

                t2 := mulmod(
                    t2,
                    mload(add(pMem, pAlpha)),
                    q
                )

                t1 := addmod(t1, t2, q)

                t := mod(sub(add(t, q), t1), q)
                t := mulmod(t, mload(add(pMem, pZhInv)), q)

                mstore( add(pMem, pEval_t) , t)

            }

            function g1_set(pR, pP) {
                mstore(pR, mload(pP))
                mstore(add(pR, 32), mload(add(pP,32)))
            }

            function g1_acc(pR, pP) {
                let mIn := mload(0x40)
                mstore(mIn, mload(pR))
                mstore(add(mIn,32), mload(add(pR, 32)))
                mstore(add(mIn,64), mload(pP))
                mstore(add(mIn,96), mload(add(pP, 32)))

                let success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0,0x20)
                }
            }

            function g1_mulAcc(pR, pP, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, mload(pP))
                mstore(add(mIn,32), mload(add(pP, 32)))
                mstore(add(mIn,64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0,0x20)
                }

                mstore(add(mIn,64), mload(pR))
                mstore(add(mIn,96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0,0x20)
                }

            }

            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn,32), y)
                mstore(add(mIn,64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0,0x20)
                }

                mstore(add(mIn,64), mload(pR))
                mstore(add(mIn,96), mload(add(pR, 32)))

                success := stati