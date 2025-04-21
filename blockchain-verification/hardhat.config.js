require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ignition-ethers");
require("dotenv").config();

// Load environment variables or use defaults
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0xd8de34287b8daacea07d9c32d9094817325257e43766b0db84a8207f19f0f086"; // Default hardhat account
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "https://sepolia.infura.io/v3/9ae4419a4d1a4e37820d0b19d9bf74a7";
const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL || "https://polygon-mumbai.infura.io/v3/YOUR-PROJECT-ID";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      chainId: 31337,
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111, // This is actually Linea Sepolia's chainId
      gasMultiplier: 1.2 // Adding gas multiplier to help with gas estimation
    },
    ethSepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/demo",  // Replace with your Ethereum Sepolia RPC URL
      accounts: [PRIVATE_KEY],
      chainId: 11155111, // Ethereum Sepolia chainId
      gasMultiplier: 1.2
    },
    mumbai: {
      url: MUMBAI_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 80001,
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
}
