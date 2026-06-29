pragma solidity 0.8.0;

contract Shuffle_encryptVerifier30Card {

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkShuffle_encryptPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pShuffle_encryptPairing := add(pMem, pShuffle_encryptPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))

                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))

                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))

                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))

                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))

                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))

                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))

                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))

                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))

                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))

                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))

                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))

                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))

                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))

                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))

                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))

                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))

                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))

                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))

                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))

                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))

                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))

                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))

                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))

                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))

                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))

                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))

                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))

                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))

                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))

                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))

                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)))

                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)))

                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)))

                g1_mulAccC(_pVk, IC35x, IC35y, calldataload(add(pubSignals, 1088)))

                g1_mulAccC(_pVk, IC36x, IC36y, calldataload(add(pubSignals, 1120)))

                g1_mulAccC(_pVk, IC37x, IC37y, calldataload(add(pubSignals, 1152)))

                g1_mulAccC(_pVk, IC38x, IC38y, calldataload(add(pubSignals, 1184)))

                g1_mulAccC(_pVk, IC39x, IC39y, calldataload(add(pubSignals, 1216)))

                g1_mulAccC(_pVk, IC40x, IC40y, calldataload(add(pubSignals, 1248)))

                g1_mulAccC(_pVk, IC41x, IC41y, calldataload(add(pubSignals, 1280)))

                g1_mulAccC(_pVk, IC42x, IC42y, calldataload(add(pubSignals, 1312)))

                g1_mulAccC(_pVk, IC43x, IC43y, calldataload(add(pubSignals, 1344)))

                g1_mulAccC(_pVk, IC44x, IC44y, calldataload(add(pubSignals, 1376)))

                g1_mulAccC(_pVk, IC45x, IC45y, calldataload(add(pubSignals, 1408)))

                g1_mulAccC(_pVk, IC46x, IC46y, calldataload(add(pubSignals, 1440)))

                g1_mulAccC(_pVk, IC47x, IC47y, calldataload(add(pubSignals, 1472)))

                g1_mulAccC(_pVk, IC48x, IC48y, calldataload(add(pubSignals, 1504)))

                g1_mulAccC(_pVk, IC49x, IC49y, calldataload(add(pubSignals, 1536)))

                g1_mulAccC(_pVk, IC50x, IC50y, calldataload(add(pubSignals, 1568)))

                g1_mulAccC(_pVk, IC51x, IC51y, calldataload(add(pubSignals, 1600)))

                g1_mulAccC(_pVk, IC52x, IC52y, calldataload(add(pubSignals, 1632)))

                g1_mulAccC(_pVk, IC53x, IC53y, calldataload(add(pubSignals, 1664)))

                g1_mulAccC(_pVk, IC54x, IC54y, calldataload(add(pubSignals, 1696)))

                g1_mulAccC(_pVk, IC55x, IC55y, calldataload(add(pubSignals, 1728)))

                g1_mulAccC(_pVk, IC56x, IC56y, calldataload(add(pubSignals, 1760)))

                g1_mulAccC(_pVk, IC57x, IC57y, calldataload(add(pubSignals, 1792)))

                g1_mulAccC(_pVk, IC58x, IC58y, calldataload(add(pubSignals, 1824)))

                g1_mulAccC(_pVk, IC59x, IC59y, calldataload(add(pubSignals, 1856)))

                g1_mulAccC(_pVk, IC60x, IC60y, calldataload(add(pubSignals, 1888)))

                g1_mulAccC(_pVk, IC61x, IC61y, calldataload(add(pubSignals, 1920)))

                g1_mulAccC(_pVk, IC62x, IC62y, calldataload(add(pubSignals, 1952)))

                g1_mulAccC(_pVk, IC63x, IC63y, calldataload(add(pubSignals, 1984)))

                g1_mulAccC(_pVk, IC64x, IC64y, calldataload(add(pubSignals, 2016)))

                g1_mulAccC(_pVk, IC65x, IC65y, calldataload(add(pubSignals, 2048)))

                g1_mulAccC(_pVk, IC66x, IC66y, calldataload(add(pubSignals, 2080)))

                g1_mulAccC(_pVk, IC67x, IC67y, calldataload(add(pubSignals, 2112)))

                g1_mulAccC(_pVk, IC68x, IC68y, calldataload(add(pubSignals, 2144)))

                g1_mulAccC(_pVk, IC69x, IC69y, calldataload(add(pubSignals, 2176)))

                g1_mulAccC(_pVk, IC70x, IC70y, calldataload(add(pubSignals, 2208)))

                g1_mulAccC(_pVk, IC71x, IC71y, calldataload(add(pubSignals, 2240)))

                g1_mulAccC(_pVk, IC72x, IC72y, calldataload(add(pubSignals, 2272)))

                g1_mulAccC(_pVk, IC73x, IC73y, calldataload(add(pubSignals, 2304)))

                g1_mulAccC(_pVk, IC74x, IC74y, calldataload(add(pubSignals, 2336)))

                g1_mulAccC(_pVk, IC75x, IC75y, calldataload(add(pubSignals, 2368)))

                g1_mulAccC(_pVk, IC76x, IC76y, calldataload(add(pubSignals, 2400)))

                g1_mulAccC(_pVk, IC77x, IC77y, calldataload(add(pubSignals, 2432)))

                g1_mulAccC(_pVk, IC78x, IC78y, calldataload(add(pubSignals, 2464)))

                g1_mulAccC(_pVk, IC79x, IC79y, calldataload(add(pubSignals, 2496)))

                g1_mulAccC(_pVk, IC80x, IC80y, calldataload(add(pubSignals, 2528)))

                g1_mulAccC(_pVk, IC81x, IC81y, calldataload(add(pubSignals, 2560)))

                g1_mulAccC(_pVk, IC82x, IC82y, calldataload(add(pubSignals, 2592)))

                g1_mulAccC(_pVk, IC83x, IC83y, calldataload(add(pubSignals, 2624)))

                g1_mulAccC(_pVk, IC84x, IC84y, calldataload(add(pubSignals, 2656)))

                g1_mulAccC(_pVk, IC85x, IC85y, calldataload(add(pubSignals, 2688)))

                g1_mulAccC(_pVk, IC86x, IC86y, calldataload(add(pubSignals, 2720)))

                g1_mulAccC(_pVk, IC87x, IC87y, calldataload(add(pubSignals, 2752)))

                g1_mulAccC(_pVk, IC88x, IC88y, calldataload(add(pubSignals, 2784)))

                g1_mulAccC(_pVk, IC89x, IC89y, calldataload(add(pubSignals, 2816)))

                g1_mulAccC(_pVk, IC90x, IC90y, calldataload(add(pubSignals, 2848)))

                g1_mulAccC(_pVk, IC91x, IC91y, calldataload(add(pubSignals, 2880)))

                g1_mulAccC(_pVk, IC92x, IC92y, calldataload(add(pubSignals, 2912)))

                g1_mulAccC(_pVk, IC93x, IC93y, calldataload(add(pubSignals, 2944)))

                g1_mulAccC(_pVk, IC94x, IC94y, calldataload(add(pubSignals, 2976)))

                g1_mulAccC(_pVk, IC95x, IC95y, calldataload(add(pubSignals, 3008)))

                g1_mulAccC(_pVk, IC96x, IC96y, calldataload(add(pubSignals, 3040)))

                g1_mulAccC(_pVk, IC97x, IC97y, calldataload(add(pubSignals, 3072)))

                g1_mulAccC(_pVk, IC98x, IC98y, calldataload(add(pubSignals, 3104)))

                g1_mulAccC(_pVk, IC99x, IC99y, calldataload(add(pubSignals, 3136)))

                g1_mulAccC(_pVk, IC100x, IC100y, calldataload(add(pubSignals, 3168)))

                g1_mulAccC(_pVk, IC101x, IC101y, calldataload(add(pubSignals, 3200)))

                g1_mulAccC(_pVk, IC102x, IC102y, calldataload(add(pubSignals, 3232)))

                g1_mulAccC(_pVk, IC103x, IC103y, calldataload(add(pubSignals, 3264)))

                g1_mulAccC(_pVk, IC104x, IC104y, calldataload(add(pubS