require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
//require('hardhat-ethernal');
require('hardhat-deploy');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.3"
      },
      {
        version: "0.6.6"
      }
    ]
  },
  paths: {
    sources : "./contracts"
  },
  namedAccounts:{
    deployer: {
      default: 0
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/bfXBx_v2S60_g5FxETt89rg9utuW0fTr",
        blockNumber: 12379711
      },
      accounts: {
        mnemonic: "clutch captain shoe salt awake harvest setup primary inmate ugly among become"
      }
    }
  }
};
