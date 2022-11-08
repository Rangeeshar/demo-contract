import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("WETHGateway", function () {

  async function deployOneYearLockFixture() {
    const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    const ONE_GWEI = 1_000_000_000;

    const lockedAmount = ONE_GWEI;
    const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    //Deploy WETHMocked
    const WETHMocked = await ethers.getContractFactory("WETHMocked");
    const wethMocked = await WETHMocked.deploy(1000000000000000);

    const WETHGateway = await ethers.getContractFactory("WETHGateway");
    const wethGateway = await WETHGateway.deploy();


  }



});
