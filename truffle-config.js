require("dotenv").config();
const secrets = process.env["SECRETS"];
const artifacts_output = process.env["ARTIFACTSOUTPUT"];
const contracts_input = process.env["CONTRACTSINPUT"];
const migration_input = process.env["MIGRATIONSCRIPT"];

const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    goerli: {
      provider: () =>
        new HDWalletProvider(secrets, "https://goerli.infura.io/v3"),
      network_id: "5",
      gasLimit: 30000000,
      timeoutBlocks: 4000,
      skipDryRun: true,
    },
    bsctestnet: {
      provider: () =>
        new HDWalletProvider(
          secrets,
          "https://data-seed-prebsc-1-s1.binance.org:8545"
        ),
      network_id: "97",
      gasLimit: 30000000,
      timeoutBlocks: 4000,
      skipDryRun: true,
    },
    sepolia: {
      provider: () =>
        new HDWalletProvider(secrets, "https://sepolia.infura.io/v3"),
      network_id: "11155111",
      gasLimit: 30000000,
      timeoutBlocks: 4000,
      skipDryRun: true,
    },
    alfajores: {
      provider: () =>
        new HDWalletProvider(
          secrets,
          "https://alfajores-forno.celo-testnet.org"
        ),
      network_id: "44787",
      gasLimit: 30000000,
      timeoutBlocks: 4000,
      skipDryRun: true,
    },
  },

  contracts_build_directory: artifacts_output,
  contracts_directory: contracts_input,
  migrations_directory: migration_input,

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.13", // Fetch exact version from solc-bin
      settings: {
        optimizer: {
          enabled: true,
          runs: 1, // Optimize for how many times you intend to run the code
        },
      },
    },
  },
};
