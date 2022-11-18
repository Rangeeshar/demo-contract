// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {IMockOracle} from "../interfaces/IMockOracle.sol";
import {IWETH} from "../interfaces/IWETH.sol";
contract LendPool  is ILendPool, Ownable{

    uint256 internal constant SECONDS_PER_YEAR = 365 days;
    uint256 internal constant THREE_MONTH = 90 days;

    // deposit part
    mapping(address => DepositData) public variableDepositBalanceList;
    mapping(address => DepositData) public threeMonthDepositBalanceList;

    // borrow part
    uint256 loanNonce;
    // nftAsset + nftTokenId => loanId
    mapping(address => mapping(uint256 => uint256)) private nftToLoanIds;
    mapping(uint256 => LoanData) public loanList;
    // 0.01% = 1
    mapping(address => uint256) public borrowRateList;
     

    // Rates
    //0.01% = 1
    uint256 public vLiquidityRate = 500;
    uint256 public threeLiquidityRate = 1000;
    // uint256 public borrowRateA = 500;
    // uint256 public borrowRateB = 1000;

    uint256 collateralRate = 3000;
    address oracleAddr;

    IWETH internal WETH;

    //0 -> v, 1 -> three
    enum DepositPeriod {
        variable,
        threeMonth
    }

    struct DepositData {
        DepositPeriod depositPeriod;
        uint256 balance;
        uint256 lastUpdateTimestamp;
    }

    struct LoanData {
        uint256 loanId;
        //0 -> Active, 1 -> Repaid
        uint256 state;
        address borrower;
        address nftAsset;
        uint256 nftTokenId;
        uint256 borrowedAmount;
        // 0 -> A, 1 -> B
        // uint8 assetClass;
        uint256 lastUpdateTimestamp;
    }

    constructor(address _oracle, address _weth) {
        oracleAddr = _oracle;
        WETH = IWETH(_weth);
    }

    //0 -> v, 1 -> three
    function deposit(
        address asset,
        uint256 amount,
        uint8 depositPeriod,
        address onBehalfOf
    ) public override {

        require(amount > 0, "Fund not enough");

        // Transfer WETH to the pool
        IERC20Upgradeable(asset).transferFrom(msg.sender,address(this),amount);

        if( depositPeriod == 0){
            variableDepositBalanceList[onBehalfOf].depositPeriod = DepositPeriod.variable;
            variableDepositBalanceList[onBehalfOf].balance += amount;
            variableDepositBalanceList[onBehalfOf].lastUpdateTimestamp = block.timestamp;

        }

        if( depositPeriod == 1){
            threeMonthDepositBalanceList[onBehalfOf].depositPeriod = DepositPeriod.threeMonth;
            threeMonthDepositBalanceList[onBehalfOf].balance += amount;
            threeMonthDepositBalanceList[onBehalfOf].lastUpdateTimestamp = block.timestamp;
        }

    }

    function vWithdraw(
        address asset,
        uint256 amount,
        address initiator,
        address to
    ) public override {
        require(amount != 0, "Amount must be greater than 0");

        updateDepositState(0, to);
        uint256 userBalance = variableDepositBalanceList[to].balance;

        require(amount <= userBalance, "Balance not enough");
        // decrease balance
        variableDepositBalanceList[to].balance = userBalance - amount;
        IERC20Upgradeable(asset).transferFrom(address(this),initiator, amount);
    }

    function fWithdraw(
        address asset,
        uint256 amount,
        address initiator,
        address to
    ) public override {
        uint256 depositedPeriod = block.timestamp - threeMonthDepositBalanceList[to].lastUpdateTimestamp;
        require(depositedPeriod >= THREE_MONTH, " Fund Locked");

        updateDepositState(1, to);
        uint256 userBalance = threeMonthDepositBalanceList[to].balance;

        require(amount != 0, "Amount must be greater than 0");
        require(amount <= userBalance, "Balance not enough");
        threeMonthDepositBalanceList[to].balance = userBalance - amount;
        IERC20Upgradeable(asset).transferFrom(address(this),initiator, amount);

    }

    function updateDepositState(uint8 depositPeriod, address onBehalfOf) public {
        
        if(depositPeriod == 0){
            uint256 accruedInterest = calculateLinearInterest(vLiquidityRate,variableDepositBalanceList[onBehalfOf].lastUpdateTimestamp);
            uint256 currentBalance = variableDepositBalanceList[onBehalfOf].balance * (10000 + accruedInterest) / 10000;
            variableDepositBalanceList[onBehalfOf].balance = currentBalance;
            variableDepositBalanceList[onBehalfOf].lastUpdateTimestamp = block.timestamp;
        }

        if(depositPeriod == 1){
            uint256 accruedInterest = calculateLinearInterest(threeLiquidityRate,threeMonthDepositBalanceList[onBehalfOf].lastUpdateTimestamp);
            uint256 currentBalance = threeMonthDepositBalanceList[onBehalfOf].balance * (10000 + accruedInterest) / 10000;
            threeMonthDepositBalanceList[onBehalfOf].balance = currentBalance;
            threeMonthDepositBalanceList[onBehalfOf].lastUpdateTimestamp = block.timestamp;
        }
    }

    function borrow(
        address reserveAssert,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) public {
        require(onBehalfOf != address(0), "Invalid OnBehalfof");
        updateBorrowState(nftAsset, nftTokenId);
        uint256 nftPrice = IMockOracle(oracleAddr).getNFTPrice(nftAsset,nftTokenId);
        require(amount <= nftPrice * collateralRate / 10000 , "Collateral not enough");

        LoanData memory loanData = LoanData(loanNonce, 0, onBehalfOf, nftAsset, nftTokenId, amount, block.timestamp);
        nftToLoanIds[nftAsset][nftTokenId] = loanNonce;
        loanList[loanNonce] = loanData;
        loanNonce++;

        IERC721Upgradeable(nftAsset).safeTransferFrom(msg.sender, address(this), nftTokenId);
        IERC20Upgradeable(address(WETH)).transferFrom(address(this),msg.sender, amount);
    }

    function updateBorrowState(address nftAsset, uint256 nftTokenId) public {
        uint256 loanId = nftToLoanIds[nftAsset][nftTokenId];
        LoanData memory loanData = loanList[loanId];
        uint256 accruedInterest = calculateLinearInterest(borrowRateList[nftAsset],loanList[loanId].lastUpdateTimestamp);
        uint256 currentDebt = loanList[loanId].borrowedAmount * ( 10000 + accruedInterest) / 10000;
        loanList[loanId].borrowedAmount = currentDebt;
        loanList[loanId].lastUpdateTimestamp = block.timestamp;
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



    // 0 -> Variable, 1 -> three month
    function getDepositData(address depositor, uint8 depositPeriod) public view returns(DepositData memory){
        
        if(depositPeriod == 0){
            return variableDepositBalanceList[depositor];
        }
        if(depositPeriod == 1){
            return threeMonthDepositBalanceList[depositor];
        }
    }

    // 0 -> A, 1 -> B
    function setNftAssetRate(address nftAsset, uint256 rate) public onlyOwner {
        borrowRateList[nftAsset] = rate;
    }

    function getCollateralLoanId(address nftAsset, uint256 nftId) view public returns(uint256){
        uint256 id = nftToLoanIds[nftAsset][nftId];
        return id;
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