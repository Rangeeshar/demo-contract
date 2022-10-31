// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;


import {ILendPool} from "../interfaces/ILendPool.sol";

contract LendPool  {

    uint256 testV;
    mapping(address => uint256) public depositList;
    mapping(address => uint256) borrowList;

    function getDepositBalance(address addr) public view returns(uint256){
        return depositList[addr];
    }

}