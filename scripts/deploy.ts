import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const mockOracleAddr = '0xB1eb6c57c5c087C3bea433c5bd5b5b063c9243E2';
  const wethAddr = '0xAb7050BD7884C22d9e55e3e9821d3a99A890de9e';


  const LendPool = await ethers.getContractFactory("LendPool");
  const lendPool = await LendPool.deploy(mockOracleAddr,wethAddr);


  await lendPool.deployed();
  console.log("lend pool: "+lendPool.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
