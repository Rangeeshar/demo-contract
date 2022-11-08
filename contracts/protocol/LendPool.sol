// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";

contract LendPool is ILendPool{

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

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
        uint256 liquidityIndex;
        uint256 borrowIndex;
        uint256 scaledLiquidityAmount;
        uint256 scaledBorrowedAmount;
        uint256 currentLiquidityRate;
        uint256 currentBorrowRate;
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

    constructor(uint256 borrowRate ) {
        // reserveData = ReserveData();
        reserveData.liquidityIndex = 100000000;
        reserveData.borrowIndex = 100000000;
        reserveData.currentBorrowRate = borrowRate;
        reserveData.lastUpdateTimestamp = block.timestamp;
    }


    /**
     * @dev deposit underlying asset into the reserve
     */
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external  override {

        updateState(reserveData);
        //transfer WETH
        IERC20Upgradeable(asset).transferFrom(msg.sender,address(this),amount);
        //update balances
        scaledDepositList[onBehalfOf]= amount * reserveData.liquidityIndex;

    }

    function withdraw(
        address reserve,
        uint256 amount,
        address to
    ) public returns (uint256){
        //TODO
    }

    function borrow(
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) public{
        //TODO
    }

    function repay(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) public returns (uint256, bool){
        //TODO
    }

    
    function createLoan(
        address initiator,
        address onBehalfOf,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    ) public returns (uint256){
        //TODO
    }

    /** 
     * @dev Update reserve state: liquidity index and borrow index
     */
    function updateState(ReserveData storage reserve) internal {

        //update liquidity index
        uint256 currentLiquidityRate = reserve.currentLiquidityRate;
        uint256 newLiquidityIndex = reserve.liquidityIndex;
        uint256 cumulatedLiquidityInterestRate = calculateLinearInterest(currentLiquidityRate, reserve.lastUpdateTimestamp);
        
        newLiquidityIndex =  reserve.currentLiquidityRate * (cumulatedLiquidityInterestRate + 1);
        reserve.currentLiquidityRate = newLiquidityIndex;

        //update liquidity index
        uint256 currentBorrowRate = reserve.currentBorrowRate;
        uint256 newBorrowIndex = reserve.borrowIndex;
        uint256 cumulatedVariableBorrowInterest = calculateLinearInterest(currentBorrowRate, reserve.lastUpdateTimestamp);
        newBorrowIndex = reserve.currentLiquidityRate * (cumulatedVariableBorrowInterest + 1);
        reserve.borrowIndex = newBorrowIndex;
    }

    /**
     * @return accrued interest ratio
     */
    function calculateLinearInterest(
        uint256 rate, 
        uint256 lastUpdateTimestamp) 
        internal returns(uint256) 
    {
        uint256 timeDifference = block.timestamp - (uint256(lastUpdateTimestamp));

        return ((rate * (timeDifference)) / SECONDS_PER_YEAR);
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