import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ContractFunction } from "hardhat/internal/hardhat-network/stack-traces/model";



describe("Lend Protocol", function () {
  console.log("------start test -------");
  const oneEther = ethers.BigNumber.from("1000000000000000000");
  var mockOracle: any;
  var weth: any;
  var mockNFT: any;
  var lendPool: any;
  var wethGateway: any;
  var mockNFTB: any;
  
  this.beforeEach(async () => {

    const MockOracle = await ethers.getContractFactory("MockOracle");
    mockOracle = await MockOracle.deploy();
   
    const WETH = await ethers.getContractFactory("WETHMocked");
    weth = await WETH.deploy();

    const MockNFT = await ethers.getContractFactory("MockNFT");
    mockNFT = await MockNFT.deploy();

    const MockNFTB = await ethers.getContractFactory("MockNFTB");
    mockNFTB = await MockNFTB.deploy();

    const LendPool = await ethers.getContractFactory("LendPool");
    lendPool = await LendPool.deploy(mockOracle.address, weth.address);

    const WETHGateway = await ethers.getContractFactory("WETHGateway");
    wethGateway = await WETHGateway.deploy(weth.address, lendPool.address, mockNFT.address);

    // nft approval
    await mockNFT.setApprovalForAll(wethGateway.address, true);
    await mockNFTB.setApprovalForAll(wethGateway.address, true);
    await wethGateway.approveNFT(mockNFT.address, lendPool.address);
    await wethGateway.approveNFT(mockNFTB.address, lendPool.address);
    // approve wethGateway to transfer  
    await lendPool.approveWETHGateway(weth.address, wethGateway.address);

  });

  describe("Mock Oracle",() => {
    it("Get NFT price", async function() {
      await lendPool.deployed();
      

    })
  })





});