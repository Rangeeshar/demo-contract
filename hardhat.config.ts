import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("hardhat-gas-reporter");

require('dotenv').config();

const pk = process.env.PK;

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    hardhat: {
    },
    goerli: {
      url: process.env.NETWORK_URL,
      chainId: 5,
      accounts: [`${pk}`]
    }
  },
  gasReporter: {
    enabled: true
  }
};

export default config;
