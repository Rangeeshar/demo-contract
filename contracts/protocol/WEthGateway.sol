// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IWETH} from "../interfaces/IWETH.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";

contract WETHGateway is IWETHGateway {

    IWETH internal WETH;
    ILendPool internal LendPool;

    constructor(address weth, address lendPool) {
        
        WETH = IWETH(weth);
        LendPool = ILendPool(lendPool);
        WETH.approve(lendPool, type(uint256).max);
    }

    function depositETH(address onBehalfOf) external payable override {
        
        WETH.deposit{value: msg.value};
        LendPool.deposit(address(WETH), msg.value, onBehalfOf);
    }

    function withdrawETH(uint256 amount, address to) external {
        
        uint256 userBalance = LendPool.getDepositBalance(msg.sender);
        uint256 amountToWithdraw = amount;

        if(amount == type(uint256).max){
            amountToWithdraw  = userBalance;
        }

        LendPool.withdraw(address(WETH), amountToWithdraw, address(this)); 
        WETH.withdraw((amountToWithdraw));
        _safeTransferETH(to,amountToWithdraw);
    }

    function borrowETH(
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external{

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
}