// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;


import {ILendPool} from "../interfaces/ILendPool.sol";

contract LendPool is ILendPool{

    mapping(address => uint256) public depositList;
    mapping(address => uint256) public borrowList;
    // nftAsset + nftTokenId => loanId
    mapping(address => mapping(uint256 => uint256)) private nftToLoanIds;
    mapping(uint256 => LoanData) loanData;

    ReserveData public reserveData;

    enum LoanState {
        Created,
        Active,
        Repaid
    }

    struct ReserveData {
        uint128 liquidityIndex;
        uint128 borrowIndex;
        uint256 liquidityAmount;
        uint256 borrowedAmount;
        uint128 currentLiquidityRate;
        uint128 currentBorrowRate;
        uint256 lastUpdateTimestamp;
    }

    struct LoanData {
        uint256 loanId;
        LoanState state;
        address borrower;
        address nftAsset;
        address nftTokenId;
        address reserveAsset;
        uint256 borrowedAmount;
    }

    constructor(uint128 borrowRate ) {
        // reserveData = ReserveData();
        reserveData.liquidityIndex = 100000000;
        reserveData.borrowIndex = 100000000;
        reserveData.currentBorrowRate = borrowRate;
        reserveData.lastUpdateTimestamp = block.timestamp;
        
    }



    /* 
        @dev deposit underlying asset into the reserve
     */
    function deposit(
        address reserve,
        uint256 amount,
        address onBehalfOf
    ) external  override {
        
        //TODO: update Reserve Data;


        //TODO: update interest rates
    }



    function getDepositBalance(address addr) public view returns(uint256){
        return depositList[addr];
    }

    function getDebtAmount(uint256 loanId) public view returns(uint256){
        return loanData[loanId].borrowedAmount;
    }

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) public view returns(uint256){
        return nftToLoanIds[nftAsset] [nftTokenId];
    }
}