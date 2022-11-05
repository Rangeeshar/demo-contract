// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;


import {ILendPool} from "../interfaces/ILendPool.sol";

contract LendPool is ILendPool{

    mapping(address => uint256) public scaledDepositList;
    mapping(address => uint256) public scaledBorrowList;
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
        uint256 scaledLiquidityAmount;
        uint256 scaledBorrowedAmount;
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

        updateState(reserveData);
    }

    /* 
        @dev Update reserve state: liquidity index and borrow index
     */
    function updateState(ReserveData storage reserve) internal {

        //update liquidity index
        uint128 currentLiquidityRate = reserve.currentLiquidityRate;
        uint128 newLiquidityIndex = reserve.liquidityIndex;
        uint128 cumulatedLiquidityInterestRate = calculateLinearInterest(currentLiquidityRate, reserve.lastUpdateTimestamp);
        
        newLiquidityIndex =  reserve.currentLiquidityRate * (cumulatedLiquidityInterestRate + 1);
        reserve.currentLiquidityRate = newLiquidityIndex;

        //update liquidity index
        uint128 currentBorrowRate = reserve.currentBorrowRate;
        uint128 newBorrowIndex = reserve.borrowIndex;
        uint128 cumulatedVariableBorrowInterest = calculateLinearInterest(currentBorrowRate, reserve.lastUpdateTimestamp);
        newBorrowIndex = reserve.currentLiquidityRate * (cumulatedVariableBorrowInterest + 1);
        reserve.borrowIndex = newBorrowIndex;
    }

    // return accrued interest ratio
    function calculateLinearInterest(
        uint128 rate, 
        uint256 lastUpdateTimestamp) 
        internal returns(uint128) 
    {

        //TODO: calculate accrued ratio
    }



    function getDepositBalance(address addr) public view returns(uint256){
        return scaledDepositList[addr];
    }

    function getDebtAmount(uint256 loanId) public view returns(uint256){
        return loanData[loanId].borrowedAmount;
    }

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) public view returns(uint256){
        return nftToLoanIds[nftAsset] [nftTokenId];
    }
}