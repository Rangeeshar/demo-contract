// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

contract MockOracle{
    function getNFTPrice(address nftAsset, uint256 nftId) public pure returns(uint256){
        return 1 ether;
    }

}