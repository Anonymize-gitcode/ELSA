pragma solidity ^0.8.0;

contract SudokuPlonkVerifier {

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

            function calculateChallanges(pProof, pMem, pPublic) {

                let a
                let b

                mstore( add(pMem, 3264 ), mload( add( pPublic, 32)))

                mstore( add(pMem, 3296 ), mload( add( pPublic, 64)))

                mstore( add(pMem, 3328 ), mload( add( pPublic, 96)))

                mstore( add(pMem, 3360 ), mload( add( pPublic, 128)))

                mstore( add(pMem, 3392 ), mload( add( pPublic, 160)))

                mstore( add(pMem, 3424 ), mload( add( pPublic, 192)))

                mstore( add(pMem, 3456 ), mload( add( pPublic, 224)))

                mstore( add(pMem, 3488 ), mload( add( pPublic, 256)))

                mstore( add(pMem, 3520 ), mload( add( pPublic, 288)))

                mstore( add(pMem, 3552 ), mload( add( pPublic, 320)))

                mstore( add(pMem, 3584 ), mload( add( pPublic, 352)))

                mstore( add(pMem, 3616 ), mload( add( pPublic, 384)))

                mstore( add(pMem, 3648 ), mload( add( pPublic, 416)))

                mstore( add(pMem, 3680 ), mload( add( pPublic, 448)))

                mstore( add(pMem, 3712 ), mload( add( pPublic, 480)))

                mstore( add(pMem, 3744 ), mload( add( pPublic, 512)))

                mstore( add(pMem, 3776 ), mload( add( pPublic, 544)))

                mstore( add(pMem, 3808 ), mload( add( pPublic, 576)))

                mstore( add(pMem, 3840 ), mload( add( pPublic, 608)))

                mstore( add(pMem, 3872 ), mload( add( pPublic, 640)))

                mstore( add(pMem, 3904 ), mload( add( pPublic, 672)))

                mstore( add(pMem, 3936 ), mload( add( pPublic, 704)))

                mstore( add(pMem, 3968 ), mload( add( pPublic, 736)))

                mstore( add(pMem, 4000 ), mload( add( pPublic, 768)))

                mstore( add(pMem, 4032 ), mload( add( pPublic, 800)))

                mstore( add(pMem, 4064 ), mload( add( pPublic, 832)))

                mstore( add(pMem, 4096 ), mload( add( pPublic, 864)))

                mstore( add(pMem, 4128 ), mload( add( pPublic, 896)))

                mstore( add(pMem, 4160 ), mload( add( pPublic, 928)))

                mstore( add(pMem, 4192 ), mload( add( pPublic, 960)))

                mstore( add(pMem, 4224 ), mload( add( pPublic, 992)))

                mstore( add(pMem, 4256 ), mload( add( pPublic, 1024)))

                mstore( add(pMem, 4288 ), mload( add( pPublic, 1056)))

                mstore( add(pMem, 4320 ), mload( add( pPublic, 1088)))

                mstore( add(pMem, 4352 ), mload( add( pPublic, 1120)))

                mstore( add(pMem, 4384 ), mload( add( pPublic, 1152)))

                mstore( add(pMem, 4416 ), mload( add( pPublic, 1184)))

                mstore( add(pMem, 4448 ), mload( add( pPublic, 1216)))

                mstore( add(pMem, 4480 ), mload( add( pPublic, 1248)))

                mstore( add(pMem, 4512 ), mload( add( pPublic, 1280)))

                mstore( add(pMem, 4544 ), mload( add( pPublic, 1312)))

                mstore( add(pMem, 4576 ), mload( add( pPublic, 1344)))

                mstore( add(pMem, 4608 ), mload( add( pPublic, 1376)))

                mstore( add(pMem, 4640 ), mload( add( pPublic, 1408)))

                mstore( add(pMem, 4672 ), mload( add( pPublic, 1440)))

                mstore( add(pMem, 4704 ), mload( add( pPublic, 1472)))

                mstore( add(pMem, 4736 ), mload( add( pPublic, 1504)))

                mstore( add(pMem, 4768 ), mload( add( pPublic, 1536)))

                mstore( add(pMem, 4800 ), mload( add( pPublic, 1568)))

                mstore( add(pMem, 4832 ), mload( add( pPublic, 1600)))

                mstore( add(pMem, 4864 ), mload( add( pPublic, 1632)))

                mstore( add(pMem, 4896 ), mload( add( pPublic, 1664)))

                mstore( add(pMem, 4928 ), mload( add( pPublic, 1696)))

                mstore( add(pMem, 4960 ), mload( add( pPublic, 1728)))

                mstore( add(pMem, 4992 ), mload( add( pPublic, 1760)))

                mstore( add(pMem, 5024 ), mload( add( pPublic, 1792)))

                mstore( add(pMem, 5056 ), mload( add( pPublic, 1824)))

                mstore( add(pMem, 5088 ), mload( add( pPublic, 1856)))

                mstore( add(pMem, 5120 ), mload( add( pPublic, 1888)))

                mstore( add(pMem, 5152 ), mload( add( pPublic, 1920)))

                mstore( add(pMem, 5184 ), mload( add( pPublic, 1952)))

                mstore( add(pMem, 5216 ), mload( add( pPublic, 1984)))

                mstore( add(pMem, 5248 ), mload( add( pPublic, 2016)))

                mstore( add(pMem, 5280 ), mload( add( pPublic, 2048)))

                mstore( add(pMem, 5312 ), mload( add( pPublic, 2080)))

                mstore( add(pMem, 5344 ), mload( add( pPublic, 2112)))

                mstore( add(pMem, 5376 ), mload( add( pPublic, 2144)))

                mstore( add(pMem, 5408 ), mload( add( pPublic, 2176)))

                mstore( add(pMem, 5440 ), mload( add( pPublic, 2208)))

                mstore( add(pMem, 5472 ), mload( add( pPublic, 2240)))

                mstore( add(pMem, 5504 ), mload( add( pPublic, 2272)))

                mstore( add(pMem, 5536 ), mload( add( pPublic, 2304)))

                mstore( add(pMem, 5568 ), mload( add( pPublic, 2336)))

                mstore( add(pMem, 5600 ), mload( add( pPublic, 2368)))

                mstore( add(pMem, 5632 ), mload( add( pPublic, 2400)))

                mstore( add(pMem, 5664 ), mload( add( pPublic, 2432)))

                mstore( add(pMem, 5696 ), mload( add( pPublic, 2464)))

                mstore( add(pMem, 5728 ), mload( add( pPublic, 2496)))

                mstore( add(pMem, 5760 ), mload( add( pPublic, 2528)))

                mstore( add(pMem, 5792 ), mload( add( pPublic, 2560)))

                mstore( add(pMem, 5824 ), mload( add( pPublic, 2592)))

                mstore( add(pMem, 5856 ), mload( add( pProof, pA)))
                mstore( add(pMem, 5888 ), mload( add( pProof, add(pA,32))))
                mstore( add(pMem, 5920 ), mload( add( pProof, add(pA,64))))
                mstore( add(pMem, 5952 ), mload( add( pProof, add(pA,96))))
                mstore( add(pMem, 5984 ), mload( add( pProof, add(pA,128))))
                mstore( add(pMem, 6016 ), mload( add( pProof, add(pA,160))))

                b := mod(keccak256(add(pMem, lastMem), 2784), q)
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

                mstore( add(pMem, pXin), a)
                a:= mod(add(sub(a, 1),q), q)
                mstore( add(pMem, pZh), a)
                mstore( add(pMem, pZhInv), a)

             