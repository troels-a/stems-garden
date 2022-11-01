require("@nomicfoundation/hardhat-toolbox");
require("@polly-tools/hardhat-polly");


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    },
  },
  polly: {
    verbose: false,
    fork: {
        hardhat: false
    }
  },
  gasReporter: {
    enabled: true,
    gasPrice: 30,
    currency: 'ETH',
    coinmarketcap: process.env.CMC_API_KEY
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  abiExporter: {
    path: './abi',
    runOnCompile: true,
    except: ['@openzeppelin', 'TestModule'],
    flat: true
  }
};
