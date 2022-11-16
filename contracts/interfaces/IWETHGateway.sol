// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IWETHGateway {

  function depositETH(address onBehalfOf, uint8 depositPeriod) external payable;

  function withdrawETH(uint256 amount, address to, uint8 depositPeriod) external;

  function borrowETH(
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf
  ) external;

  function repayETH(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external payable returns (uint256, bool);

}