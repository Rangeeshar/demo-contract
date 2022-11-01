// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPool {

    function deposit(
        address reserve,
        uint256 amount,
        address onBehalfOf
    ) external;

    function withdraw(
        address reserve,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external;

    function repay(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) external returns (uint256, bool);

    function getDepositBalance(address addr) external returns(uint256);

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns(uint256);
}