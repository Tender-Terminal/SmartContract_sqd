import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
const INFURA_API_KEY = "c4c5cc0e44b745e08e2056827b31ec05" ;
const SEPOLIA_PRIVATE_KEY = "75ea5a9b8cd5f9d374208c6e292bcb5d79227bf3059cd08f19cba56b8607246b";
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
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts:[SEPOLIA_PRIVATE_KEY],
    },
    
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

