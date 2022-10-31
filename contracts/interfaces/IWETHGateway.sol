// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IWETHGateway {

  function depositETH(address onBehalfOf) external payable;

  function withdrawETH(uint256 amount, address to) external;

  function borrowETH(
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf
  ) external;

}