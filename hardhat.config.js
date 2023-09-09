require("@nomicfoundation/hardhat-toolbox");

const { PRIVATE_KEY, ETHERSCAN_API_KEY, POLYGONSCAN_API_KEY } = require('./secret.json');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
  version: "0.8.19",
  settings: {
    // "viaIR": true,
    optimizer: {
      enabled: true,
      // runs: 100000,
    }
   }
  },
  networks: {
    polygon: {
      url: `https://polygon-rpc.com/`,
      // url: `https://rpc-mainnet.maticvigil.com`,
      // url: `https://rpc.ankr.com/polygon/`,
      accounts: [`0x${PRIVATE_KEY}`],
      // gasPrice: 500 * 10 ** 9,
      chainId: 137
    },
    polygonMumbai: {
      // url: `https://matic-mumbai.chainstacklabs.com`,
      url: `https://rpc.ankr.com/polygon_mumbai`,
      // url: `https://polygon-mumbai.blockpi.network/v1/rpc/public`,
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 80001
    },
    sepolia: {
      // url: `https://endpoints.omniatech.io/v1/eth/sepolia/public`,
      // url: `https://api.zan.top/node/v1/eth/sepolia/public`,
      url: `https://eth-sepolia.public.blastapi.io`,
      // url: `https://rpc-sepolia.rockx.com`,
      // url: `https://rpc2.sepolia.org`,
      // url: `https://sepolia.gateway.tenderly.co`,
      // url: `https://rpc.notadegen.com/eth/sepolia`,
      // url: `https://gateway.tenderly.co/public/sepolia`,
      accounts: [`0x${PRIVATE_KEY}`],
      chainId: 11155111
    },
  },
  etherscan: {
    apiKey: {
      sepolia: `${ETHERSCAN_API_KEY}`,
      polygon: `${POLYGONSCAN_API_KEY}`,
      polygonMumbai: `${POLYGONSCAN_API_KEY}`,
    }
  },
};
