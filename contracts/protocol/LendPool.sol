// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;


import {ILendPool} from "../interfaces/ILendPool.sol";

contract LendPool  {

    mapping(address => uint256) public depositList;
    mapping(address => uint256) public borrowList;
    // nftAsset + nftTokenId => loanId
    mapping(address => mapping(uint256 => uint256)) private nftToLoanIds;
    mapping(uint256 => LoanData) loanData;

    enum LoanState {
        Created,
        Active,
        Repaid
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