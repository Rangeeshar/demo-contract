import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  
  var mockNFT: any;
  var mockNFTB: any;


  const MockNFT = await ethers.getContractFactory("MockNFT");
  mockNFT = await MockNFT.deploy();

  const MockNFTB = await ethers.getContractFactory("MockNFTB");
  mockNFTB = await MockNFTB.deploy();

  mockNFT.deployed();
  mockNFTB.deployed();
  console.log("Mock NFT : " + mockNFT.address);
  console.log("Mock NFT B : " + mockNFTB.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
