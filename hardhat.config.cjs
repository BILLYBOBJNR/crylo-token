require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");

module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    bscMainnet: {
      url: "https://bsc-dataseed.binance.org/",
      accounts: ["0xc445bce5636df7db89e001d8fe9cd7c10d9609f0fbaa27958652bf83b0e51ca2"]
    },
  },
  etherscan: {
    apiKey: "QKSWNY668BDQPVHH1R6HUS3KB5EM83NQKT"
  }
};
