import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  

  var weth: any;


  const WETH = await ethers.getContractFactory("WETHMocked");
  weth = await WETH.deploy();;

  weth.deployed();
  console.log(weth.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
