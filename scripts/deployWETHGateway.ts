import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const mockOracleAddr = '0xB1eb6c57c5c087C3bea433c5bd5b5b063c9243E2';
  const wethAddr = '0xAb7050BD7884C22d9e55e3e9821d3a99A890de9e';
  const mockNFTAddr = '0x69C3247c59797A5aE034Bb4DCE08d0BA6674fE9e';
  const mockNFTBAddr = '0x22FFEA7238B096493CF2E5401F4F3f6264c4d796';
  const lendPoolAddr = '0xC6F667fA0562EE71852358e8C01f167d7a5eBBBC';


  const WETHGateway = await ethers.getContractFactory("WETHGateway");
  const wethGateway = await WETHGateway.deploy(wethAddr, lendPoolAddr, mockNFTAddr);
 
  // // Approval
  // await mockNFT.setApprovalForAll(wethGateway.address, true);
  // await mockNFTB.setApprovalForAll(wethGateway.address, true);
//   await wethGateway.approveNFT(mockNFT.address, lendPool.address);
//   await wethGateway.approveNFT(mockNFTB.address, lendPool.address);
  // // approve wethGateway to transfer  
  // await lendPool.approveWETHGateway(weth.address, wethGateway.address);
  


  await wethGateway.deployed();
  console.log("weth gateway: "+wethGateway.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
