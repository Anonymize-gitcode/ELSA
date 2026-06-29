pragma solidity ^0.8.0;

contract SudokuPlonkVerifier {

    uint32 constant n =   32768;

    uint16 constant nPublic =  81;

    uint16 constant nLagrange = 81;

    uint256 constant Qmx = 10927825355279323819909025888497523658919746891547457607568249713166370480599;

    uint256 constant Qmy = 20284708358263747284632224820253547828703594454053171690239497966144748606043;

    uint256 constant Qlx = 13975183133584314355388684914868772933593505609838205304059025808658338014353;

    uint256 constant Qly = 6384235965511178557262425281731238290474883831738768432398206694769244481133;

    uint256 constant Qrx = 13799688968642751071882984831108740988444777504518083989393509507896500999355;

    uint256 constant Qry = 9737589682214799605696755064569819621890250878623026787023844908090265416067;

    uint256 constant Qox = 6849344489999861591887517290406564413198406721478000565964137305369621923172;

    uint256 constant Qoy = 918592910473761327277705279355105980682624200365526889786939488638576034350;

    uint256 constant Qcx = 336848023000595324162009869641232490367580998671035477610575219701473903942;

    uint256 constant Qcy = 8704678468704931340195761122537734110827129306618285404787055899946043053099;

    uint256 constant S1x = 1906134917630151681124255075666258911535412284139099363686091363036832481438;

    uint256 constant S1y = 14673929996297838862557843912867089239672368789683155346888750618579788733396;

    uint256 constant S2x = 17399309190551051736999378912000352959695380918455778624541966002192732733682;

    uint256 constant S2y = 16695172796448134106074686717937198138633322240617736922827752167583640738580;

    uint256 constant S3x = 12123308925324143435018231592158987010208816840191052759551799971896140417138;

    uint256 constant S3y = 3691503116710811145500032892908560540315637519916713845910393201446583627773;

    uint256 constant k1 = 2;

    uint256 constant k2 = 3;

    uint256 constant X2x1 = 21831381940315734285607113342023901060522397560371972897001948545212302161822;

    uint256 constant X2x2 = 17231025384763736816414546592865244497437017442647097510447326538965263639101;

    uint256 constant X2y1 = 2388026358213174446665280700919698872609886601280537296205114254867301080648;

    uint256 constant X2y2 = 11507326595632554467052522095592665270651932854513688777769618397986436103170;

    uint256 constant q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 constant qf = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    uint256 constant w1 = 20402931748843538985151001264530049874871572933694634836567070693966133783803;

    uint256 constant G1x = 1;

    uint256 constant G1y = 2;

    uint256 constant G2x1 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;

    uint256 constant G2x2 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;

    uint256 constant G2y1 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;

    uint256 constant G2y2 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;

    uint16 constant pA = 32;

    uint16 constant pB = 96;

    uint16 constant pC = 160;

    uint16 constant pZ = 224;

    uint16 constant pT1 = 288;

    uint16 constant pT2 = 352;

    uint16 constant pT3 = 416;

    uint16 constant pWxi = 480;

    uint16 constant pWxiw = 544;

    uint16 constant pEval_a = 608;

    uint16 constant pEval_b = 640;

    uint16 constant pEval_c = 672;

    uint16 constant pEval_s1 = 704;

    uint16 constant pEval_s2 = 736;

    uint16 constant pEval_zw = 768;

    uint16 constant pEval_r = 800;

    uint16 constant pAlpha = 0;

    uint16 constant pBeta = 32;

    uint16 constant pGamma = 64;

    uint16 constant pXi = 96;

    uint16 constant pXin = 128;

    uint16 constant pBetaXi = 160;

    uint16 constant pV1 = 192;

    uint16 constant pV2 = 224;

    uint16 constant pV3 = 256;

    uint16 constant pV4 = 288;

    uint16 constant pV5 = 320;

    uint16 constant pV6 = 352;

    uint16 constant pU = 384;

    uint16 constant pPl = 416;

    uint16 constant pEval_t = 448;

    uint16 constant pA1 = 480;

    uint16 constant pB1 = 544;

    uint16 constant pZh = 608;

    uint16 constant pZhInv = 640;

    uint16 constant pEval_l1 = 672;

    uint16 constant pEval_l2 = 704;

    uint16 constant pEval_l3 = 736;

    uint16 constant pEval_l4 = 768;

    uint16 constant pEval_l5 = 800;

    uint16 constant pEval_l6 = 832;

    uint16 constant pEval_l7 = 864;

    uint16 constant pEval_l8 = 896;

    uint16 constant pEval_l9 = 928;

    uint16 constant pEval_l10 = 960;

    uint16 constant pEval_l11 = 992;

    uint16 constant pEval_l12 = 1024;

    uint16 constant pEval_l13 = 1056;

    uint16 constant pEval_l14 = 1088;

    uint16 constant pEval_l15 = 1120;

    uint16 constant pEval_l16 = 1152;

    uint16 constant pEval_l17 = 1184;

    uint16 constant pEval_l18 = 1216;

    uint16 constant pEval_l19 = 1248;

    uint16 constant pEval_l20 = 1280;

    uint16 constant pEval_l21 = 1312;

    uint16 constant pEval_l22 = 1344;

    uint16 constant pEval_l23 = 1376;

    uint16 constant pEval_l24 = 1408;

    uint16 constant pEval_l25 = 1440;

    uint16 constant pEval_l26 = 1472;

    uint16 constant pEval_l27 = 1504;

    uint16 constant pEval_l28 = 1536;

    uint16 constant pEval_l29 = 1568;

    uint16 constant pEval_l30 = 1600;

    uint16 constant pEval_l31 = 1632;

    uint16 constant pEval_l32 = 1664;

    uint16 constant pEval_l33 = 1696;

    uint16 constant pEval_l34 = 1728;

    uint16 constant pEval_l35 = 1760;

    uint16 constant pEval_l36 = 1792;

    uint16 constant pEval_l37 = 1824;

    uint16 constant pEval_l38 = 1856;

    uint16 constant pEval_l39 = 1888;

    uint16 constant pEval_l40 = 1920;

    uint16 constant pEval_l41 = 1952;

    uint16 constant pEval_l42 = 1984;

    uint16 constant pEval_l43 = 2016;

    uint16 constant pEval_l44 = 2048;

    uint16 constant pEval_l45 = 2080;

    uint16 constant pEval_l46 = 2112;

    uint16 constant pEval_l47 = 2144;

    uint16 constant pEval_l48 = 2176;

    uint16 constant pEval_l49 = 2208;

    uint16 constant pEval_l50 = 2240;

    uint16 constant pEval_l51 = 2272;

    uint16 constant pEval_l52 = 2304;

    uint16 constant pEval_l53 = 2336;

    uint16 constant pEval_l54 = 2368;

    uint16 constant pEval_l55 = 2400;

    uint16 constant pEval_l56 = 2432;

    uint16 constant pEval_l57 = 2464;

    uint16 constant pEval_l58 = 2496;

    uint16 constant pEval_l59 = 2528;

    uint16 constant pEval_l60 = 2560;

    uint16 constant pEval_l61 = 2592;

    uint16 constant pEval_l62 = 2624;

    uint16 constant pEval_l63 = 2656;

    uint16 constant pEval_l64 = 2688;

    uint16 constant pEval_l65 = 2720;

    uint16 constant pEval_l66 = 2752;

    uint16 constant pEval_l67 = 2784;

    uint16 constant pEval_l68 = 2816;

    uint16 constant pEval_l69 = 2848;

    uint16 constant pEval_l70 = 2880;

    uint16 constant pEval_l71 = 2912;

    uint16 constant pEval_l72 = 2944;

    uint16 constant pEval_l73 = 2976;

    uint16 constant pEval_l74 = 3008;

    uint16 constant pEval_l75 = 3040;

    uint16 constant pEval_l76 = 3072;

    uint16 constant pEval_l77 = 3104;

    uint16 constant pEval_l78 = 3136;

    uint16 constant pEval_l79 = 3168;

    uint16 constant pEval_l80 = 3200;

    uint16 constant pEval_l81 = 3232;

    uint16 constant lastMem = 3264;

    mapping(address => uint) public balances;

    function withdraw_ReentrancyWithoutMutex_23nt(uint _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
        balances[msg.sender] -= _amount;
    }

}
