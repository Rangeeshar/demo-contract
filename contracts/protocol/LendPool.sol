// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {IMockOracle} from "../interfaces/IMockOracle.sol";
import {IWETH} from "../interfaces/IWETH.sol";
contract LendPool is ILendPool{

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    mapping(address => uint256) public scaledDepositList;
    mapping(address => uint256) public scaledBorrowList;
    
    // nftAsset + nftTokenId => loanId
    mapping(address => mapping(uint256 => uint256)) private nftToLoanIds;
    mapping(address => NFTData) public nftDataList;
    mapping(uint256 => LoanData) loanDataList;
    uint256 loanNonce;
    uint32 collateralRate;
    address oracleAddr;


    ReserveData public reserveData;

    IWETH internal WETH;

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
        uint256 nftTokenId;
        address reserveAsset;
        uint256 borrowedAmount;
    }

    struct NFTData {
        address nftAddress;
        uint8 id;
        uint256 maxSupply;
        uint256 maxTokenId;
    }

    constructor(uint256 borrowRate, address _oracleAddr ) {
        // reserveData = ReserveData();
        reserveData = ReserveData({
            liquidityIndex:100000000,
            borrowIndex:100000000,
            scaledLiquidityAmount: 0,
            scaledBorrowedAmount: 0,
            currentLiquidityRate: 0,
            currentBorrowRate:borrowRate,
            lastUpdateTimestamp:block.timestamp
        });
        // reserveData.liquidityIndex = 100000000;
        // reserveData.borrowIndex = 100000000;
        // reserveData.currentBorrowRate = borrowRate;
        // reserveData.lastUpdateTimestamp = block.timestamp;
        //1 = 0.01%
        collateralRate = 5000;
        oracleAddr = _oracleAddr;
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
        scaledDepositList[onBehalfOf] += amount * reserveData.liquidityIndex / 100000000;
    }

    function withdraw(
        address asset,
        uint256 amount,
        address initiator,
        address to
    ) public returns (uint256){
        
        uint256 liquidityIndex = reserveData.liquidityIndex;
        require(amount != 0, "Amount must be greater than 0");
        require(amount <= scaledDepositList[to] * liquidityIndex / 100000000, "Balance not enough");

        updateState(reserveData);
        //transfer WETH to WETHGateway
        IERC20Upgradeable(asset).transferFrom(address(this),initiator, amount);
        //update balances
        scaledDepositList[to] -=  amount * 100000000 / liquidityIndex;
        return amount;
    }

    function borrow(
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) public{
        
        require(onBehalfOf != address(0), "Invalid OnBehalfof");
        NFTData storage nftData = nftDataList[nftAsset];
        updateState(reserveData);

        //convert asset amount to ETH
        uint256 nftPrice = IMockOracle(oracleAddr).getNFTPrice(nftAsset,nftTokenId);
        //validate
        require(amount <= nftPrice * collateralRate / 10000 , "Collateral not enough");
        //transfer NFT
        IERC721Upgradeable(nftAsset).safeTransferFrom(msg.sender, address(this), nftTokenId);
        createLoan( onBehalfOf, nftAsset, nftTokenId, reserveAsset, amount);
    }

    function repay(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) public returns (uint256, bool){
        //TODO
    }

    function createLoan(
        address onBehalfOf,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    ) public returns (uint256){
        uint borrowIndex = reserveData.borrowIndex;
        uint256 scaledBorrowAmount = amount * 100000000 / (borrowIndex + 1);
        LoanData memory ld = LoanData(loanNonce,LoanState.Active,onBehalfOf,nftAsset,nftTokenId, reserveAsset, scaledBorrowAmount);
        nftToLoanIds[nftAsset][nftTokenId] = loanNonce;
        loanDataList[loanNonce] = ld;
        loanNonce++;
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
        internal view returns(uint256) 
    {
        uint256 timeDifference = block.timestamp - (uint256(lastUpdateTimestamp));

        return ((rate * (timeDifference)) / SECONDS_PER_YEAR);
    }



    function getDepositBalance(address addr) public view returns(uint256){
        return scaledDepositList[addr];
    }

    function getDebtAmount(uint256 loanId) public view returns(uint256){
        return loanDataList[loanId].borrowedAmount;
    }

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) public view returns(uint256){
        return nftToLoanIds[nftAsset] [nftTokenId];
    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function approveWETHGateway(address wethAddr, address wethGatewayAddr) public returns(bool){
        WETH = IWETH(wethAddr);
        WETH.approve(wethGatewayAddr, type(uint256).max);
    }

}