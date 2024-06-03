import { HardhatUserConfig } from "hardhat/config";
import "dotenv/config";

import "@nomicfoundation/hardhat-toolbox";

const infuraKey = process.env.INFURA_API_KEY;
const privateKey = process.env.PRIVATE_KEY?process.env.PRIVATE_KEY:"";
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
      viaIR: true,
    },
  },
  networks:{
    sepolia:{
      url: `https://sepolia.infura.io/v3/${infuraKey}`,
      accounts:[privateKey],
    },
    mainnet:{
      url: `https://mainnet.infura.io/v3/${infuraKey}`,
      accounts:[privateKey],
    }
  },
  etherscan: {
    apiKey: {
      sepolia: 'ED2NED96C214Y891MR98PZZ1Q45VTFYZRV'
    },
  },
  gasReporter: {enabled: true},
  sourcify: {
    enabled: true
  }
};

export default config;

