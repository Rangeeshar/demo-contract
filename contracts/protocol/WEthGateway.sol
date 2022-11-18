// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";

contract WETHGateway is IWETHGateway, ERC721HolderUpgradeable {

    IWETH internal WETH;
    ILendPool internal LendPool;

    constructor(address _weth, address lendPool, address nftAsset) {
        
        WETH = IWETH(_weth);
        LendPool = ILendPool(lendPool);
        WETH.approve(lendPool, type(uint256).max);
        IERC721Upgradeable(nftAsset).setApprovalForAll(lendPool,true);

    }

    function depositETH(address onBehalfOf, uint8 depositPeriod) external payable override {
        
        WETH.deposit{value: msg.value}();
        LendPool.deposit(address(WETH), msg.value,depositPeriod ,onBehalfOf);
    }

    function withdrawETH(uint256 amount, address to, uint8 depositPeriod) external {
        
        // uint256 userBalance = LendPool.getDepositBalance(msg.sender);
        uint256 amountToWithdraw = amount;

        // if(amount == type(uint256).max){
        //     amountToWithdraw  = userBalance;
        // }

        if(depositPeriod == 0){
            LendPool.vWithdraw(address(WETH), amountToWithdraw, address(this),to); 
        }

        if(depositPeriod == 1){
            LendPool.fWithdraw(address(WETH), amountToWithdraw, address(this),to); 
        }
        
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(to,amountToWithdraw);
    }

    function borrowETH(
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external{
        
        uint256 loanId = LendPool.getCollateralLoanId(nftAsset, nftTokenId);
        if(loanId == 0){
            IERC721Upgradeable(nftAsset).safeTransferFrom(msg.sender, address(this), nftTokenId);
        }

        LendPool.borrow(address(WETH), amount, nftAsset, nftTokenId, onBehalfOf);
        WETH.withdraw(amount);
        _safeTransferETH(onBehalfOf, amount);
    }

    function repayETH(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) external payable returns (uint256, bool){
        (uint256 repayAmount, bool repayAll) = _repayETH(nftAsset, nftTokenId, amount);

        // refund remaining dust eth
        if (msg.value > repayAmount) {
        _safeTransferETH(msg.sender, msg.value - repayAmount);
        }

        return (repayAmount, repayAll);
    }

    function _repayETH(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) internal returns (uint256, bool) {

        // uint256 loanId = LendPool.getCollateralLoanId(nftAsset, nftTokenId);
        // require(loanId > 0, "collateral loan id not exist");

        // address reserveAsset = address(WETH);
        // uint256 repayDebtAmount = LendPool.getDebtAmount(loanId);

        // if(amount < repayDebtAmount){
        //     repayDebtAmount = amount;
        // }

        // require(msg.value >= repayDebtAmount,"msg.value is less than repay amount");

        // WETH.deposit{value: repayDebtAmount}();
        // // burn: burnt amount of the loan
        // (uint256 paybackAmount, bool burn) = LendPool.repay(nftAsset, nftTokenId, amount);

        // return (paybackAmount, burn);
    }

    /**
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }
    
}