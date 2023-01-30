// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPool {
    
    function deposit(
        address reserve,
        uint256 amount,
        uint8 depositPeriod,
        address onBehalfOf
    ) external;

    function vWithdraw(
        address asset,
        uint256 amount,
        address initiator,
        address to
    ) external ;

    function fWithdraw(
        address asset,
        uint256 amount,
        address initiator,
        address to
    ) external ;

     function borrow(
        address reserveAssert,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external;

    function updateBorrowState(address nftAsset, uint256 nftTokenId) external;

    function repay(
        address nftAsset,
        uint256 nftTokenId,
        uint256 loanId,
        uint256 amount
    ) external returns (uint256);

    function getCollateralLoanId(
        address nftAsset, 
        uint256 nftId
    ) external returns(uint256);

    function getUserLoan(address borrower) external returns(uint256);

    function getDebtAmount(uint256 loanId) external returns(uint256);
}