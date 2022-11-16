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
  
  
  this.beforeEach(async () => {

    const MockOracle = await ethers.getContractFactory("MockOracle");
    mockOracle = await MockOracle.deploy();
    console.log("oracle address= " + mockOracle.address);
    const WETH = await ethers.getContractFactory("WETHMocked");
    weth = await WETH.deploy();

    const MockNFT = await ethers.getContractFactory("MockNFT");
    mockNFT = await MockNFT.deploy();


  });

  describe("Mock Oracle",() => {
    it("Get NFT price", async function() {
      await mockOracle.deployed();
      
      const priceOfNFT = await mockOracle.getNFTPrice('0x846684d5db5A149bAb306FeeE123a268a9E8A7E4','0x846684d5db5A149bAb306FeeE123a268a9E8A7E4');

      expect(priceOfNFT).to.equal(oneEther);
    })
  })

  describe("WETH",() => {
    it("Mint WETH", async function() {
      const [owner, addr1, addr2] = await ethers.getSigners();
      await weth.deployed();
      
      //deposit Ether to WETH
      await weth.deposit({value: ethers.utils.parseUnits("1","ether")});
      const wethBalance = await weth.balanceOf(owner.address);

      expect(wethBalance).to.equal(oneEther);
    })

    it("Withdraw ETH", async function() {
      const [owner, addr1, addr2] = await ethers.getSigners();
      await weth.deployed();
      
      //deposit and withdraw Ether to WETH
      await weth.deposit({value: ethers.utils.parseUnits("1","ether")});
      await weth.withdraw(ethers.utils.parseUnits("1","ether"));
      const wethBalance = await weth.balanceOf(owner.address);
      // console.log(wethBalance);
      expect(wethBalance).to.equal(0);
    })
  })

  describe("Mock NFT",() => {
    it("Mint NFT", async function() {
      const [owner, addr1, addr2] = await ethers.getSigners();
      await mockNFT.deployed();
      
      //mint nft
      await mockNFT.mint(owner.address);
      const nftBalance = await mockNFT.balanceOf(owner.address);
      expect(nftBalance).to.equal(1);
    })
  }) 

  describe("Lend Pool", async () => {

    it("Init contract", async function() {
      const [owner, addr1, addr2] = await ethers.getSigners();
      const LendPool = await ethers.getContractFactory("LendPool");
      const lendPool = await LendPool.deploy(1000, mockOracle.address);
      await lendPool.deployed();
    })
 
    it("Deposit and withdraw 1 Ether from WETHGateway to Lend Pool", async function() {
      const [owner, addr1, addr2] = await ethers.getSigners();
      var lendPool: any;
      var wethGateway: any;
      
      const LendPool = await ethers.getContractFactory("LendPool");
      const WETHGateway = await ethers.getContractFactory("WETHGateway");
      
      /**
       * @param {uint256} Borrow rate: set borrow rate to 10%: 1 = 0.01%
       * @param {address} Oracle addree 
       **/
      lendPool = await LendPool.deploy(1000, mockOracle.address);
      wethGateway = await WETHGateway.deploy(weth.address, lendPool.address, mockNFT.address);
      await mockOracle.deployed();
      await wethGateway.deployed();
      await lendPool.deployed();

      await lendPool.approveWETHGateway(weth.address, wethGateway.address);
      await wethGateway.depositETH(owner.address,{value: ethers.utils.parseUnits("1","ether")});

      // check WETH balance of lend pool
      const balanceOfPool = await weth.balanceOf(lendPool.address);
      expect(balanceOfPool).to.equal(oneEther);

      //check balance of depositor
      const balanceOfDep = await lendPool.getDepositBalance(owner.address);
      expect(balanceOfDep).to.equal(oneEther);

      //withdraw eth from the pool
      await wethGateway.withdrawETH(oneEther, owner.address);
      //check balance of depositor
      const balanceAfterWithdraw = await lendPool.getDepositBalance(owner.address);
      expect(balanceAfterWithdraw).to.equal(0);


    })

    

    it("borrow  Ether from Lend Pool", async function() {
      const [owner, addr1, addr2] = await ethers.getSigners();
      var lendPool: any;
      var wethGateway: any;
      
      const LendPool = await ethers.getContractFactory("LendPool");
      const WETHGateway = await ethers.getContractFactory("WETHGateway");
      
      lendPool = await LendPool.deploy(1000, mockOracle.address);
      wethGateway = await WETHGateway.deploy(weth.address, lendPool.address, mockNFT.address);
      await mockOracle.deployed();
      await wethGateway.deployed();
      await lendPool.deployed();




      await lendPool.approveWETHGateway(weth.address, wethGateway.address);
      // Deposit 20 ether to the pool
      await wethGateway.depositETH(owner.address,{value: ethers.utils.parseUnits("20","ether")});


            //check borrow index value
            const borrowIndex = await lendPool.reserveData();
            console.log("bowrrow index"+borrowIndex);
            // expect(borrowIndex).to.equal(100000000);

      // check WETH balance of lend pool
      const balanceOfPool = await weth.balanceOf(lendPool.address);
      expect(balanceOfPool).to.equal(oneEther.mul(20));

      // mint 1 nft to owner address
      await mockNFT.mint(owner.address);
      const nftBalance = await mockNFT.balanceOf(owner.address);
      //check nft owed by the address
      const ownerAddress = await mockNFT.ownerOf(0);
      expect(nftBalance).to.equal(1);
      expect(ownerAddress).to.equal(owner.address);


      // approve nft
      await mockNFT.setApprovalForAll(wethGateway.address,true);
      // await mockNFT.approve(wethGateway.address,0);
      
      // await mockNFT.approve(wethGateway.address,1);
      // balance before borrow
      const pBalance = await owner.getBalance();
      console.log("pbalance "+ pBalance);
      // borrow ether from the pool
      // await wethGateway.borrowETH(oneEther.div(10), mockNFT.address, 0, owner.address);

      // const balanceOfDep = await lendPool.getDepositBalance(owner.address);
      // expect(balanceOfDep).to.equal(oneEther);
    })

    
  })

});