import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ContractFunction } from "hardhat/internal/hardhat-network/stack-traces/model";



describe("Lend Pool", function () {
  console.log("------start test -------");
  const oneEther = ethers.BigNumber.from("1000000000000000000");
  let mockOracle:any;
  
  this.beforeEach(async () => {

    const MockOracle = await ethers.getContractFactory("MockOracle");
    mockOracle = await MockOracle.deploy();
  });

  describe("Mock Oracle",() => {
    it("Get NFT price", async function() {
      const [owner, addr1, addr2] = await ethers.getSigners();
      await mockOracle.deployed();
      
      const priceOfNFT = await mockOracle.getNFTPrice('0x846684d5db5A149bAb306FeeE123a268a9E8A7E4','0x846684d5db5A149bAb306FeeE123a268a9E8A7E4');

      expect(priceOfNFT).to.equal(oneEther);
    })
  })





});