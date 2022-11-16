// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {IMockOracle} from "../interfaces/IMockOracle.sol";
import {IWETH} from "../interfaces/IWETH.sol";
contract LendPool  is ILendPool{

    uint256 internal constant SECONDS_PER_YEAR = 365 days;
    uint256 internal constant THREE_MONTH = 90 days;

    mapping(address => DepositData) public variableDepositBalanceList;
    mapping(address => DepositData) public threeMonthDepositBalanceList;
    mapping(address => uint256) public borrowDebtList;

    //0.01% = 1
    uint256 public vLiquidityRate = 500;
    uint256 public threeLiquidityRate = 1000;

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

    constructor() {
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

        updateDepositState(DepositPeriod.variable, to);
        uint256 userBalance = variableDepositBalanceList[to].balance;

        require(amount <= userBalance, "Balance not enough");
        
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

        updateDepositState(DepositPeriod.threeMonth, to);
        uint256 userBalance = threeMonthDepositBalanceList[to].balance;

        require(amount != 0, "Amount must be greater than 0");
        require(amount <= userBalance, "Balance not enough");

    }

    function updateDepositState(DepositPeriod depositPeriod, address onBehalfOf) internal {
        
        if(depositPeriod == DepositPeriod.variable){
            uint256 accruedInterest = calculateLinearInterest(vLiquidityRate,variableDepositBalanceList[onBehalfOf].lastUpdateTimestamp);
            uint256 currentBalance = variableDepositBalanceList[onBehalfOf].balance * (10000 + accruedInterest) / 10000;
            variableDepositBalanceList[onBehalfOf].balance = currentBalance;
        }

        if(depositPeriod == DepositPeriod.threeMonth){
            uint256 accruedInterest = calculateLinearInterest(threeLiquidityRate,threeMonthDepositBalanceList[onBehalfOf].lastUpdateTimestamp);
            uint256 currentBalance = threeMonthDepositBalanceList[onBehalfOf].balance * (10000 + accruedInterest) / 10000;
            threeMonthDepositBalanceList[onBehalfOf].balance = currentBalance;
        }
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