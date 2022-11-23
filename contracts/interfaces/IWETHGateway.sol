// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

interface IWETHGateway {

  /**
   * @param {onBehalfOf} depositor
   * @param {depositPeriod} 0 -> variable period; 1 -> fixed period (3 months)
   */
  function depositETH(address onBehalfOf, uint8 depositPeriod) external payable;

  /**
   * @param {amount} withdrawal amount
   * @param {to} address where fund goes to
   * @param {depositPeriod} 0 -> variable period; 1 -> fixed period (3 months)
   */
  function withdrawETH(uint256 amount, address to, uint8 depositPeriod) external;

  /**
   * @param {amount} withdrawal amount
   * @param {nftAsset} NFT collection address
   * @param {nftTokenId} NFT token ID
   * @param {onBehalfOf} depositor
   */
  function borrowETH(
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf
  ) external;

  /**
   * @param {nftAsset} NFT collection address
   * @param {nftTokenId} NFT token ID
   */
  function repayETH(
    address nftAsset,
    uint256 nftTokenId
  ) external payable returns ( bool);
}