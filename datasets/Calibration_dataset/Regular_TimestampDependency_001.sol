pragma solidity ^0.4.24;

contract airdrop{

    function transfer(address from,address caddress,address[] _tos,uint v)public returns (bool){
        uint256 _ts = block.timestamp;
        require(_tos.length > 0);
        bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){

            caddress.call(id,from,_tos[i],v);
        }
        return true;
    }
}
