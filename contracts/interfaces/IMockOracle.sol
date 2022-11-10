// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IMockOracle{
    function getNFTPrice(address nftAsset, uint256 nftId) external returns(uint256);
}