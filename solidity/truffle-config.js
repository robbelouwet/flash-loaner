require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
	contracts_directory: "./contracts",
	networks: {
		bsc: {
			provider: () =>
				new HDWalletProvider(
					process.env.BSC_MNEMONIC,
					`https://bsc-dataseed1.binance.org`
				),
			network_id: 56,
			confirmations: 10,
			timeoutBlocks: 200,
			skipDryRun: true,
		},

		bsctestnet: {
			provider: () =>
				new HDWalletProvider(
					process.env.BSC_MNEMONIC,
					`https://data-seed-prebsc-1-s1.binance.org:8545`
				),
			network_id: 97,
			confirmations: 5,
			timeoutBlocks: 200,
			skipDryRun: true,
			production: true,
		},

		ropsten: {
			provider: (_) =>
				new HDWalletProvider({
					mnemonic: process.env.ROPSTEN_MNEMONIC,
					providerOrUrl: `https://ropsten.infura.io/v3/${process.env.INFURA_KEY}`,
					//derivationPath: "m/44'/60'/0'/0/", // = default
					//addressIndex: 0, // = default
					chainId: 3,
				}),
			network_id: 3,
			gas: 5500000,
			confirmations: 2,
			timeoutBlocks: 200,
			skipDryRun: true,
		},
		geth: {
			host: "localhost",
			port: 8545,
			network_id: 3,
			gas: 4700000,
		},
		development: {
			host: "127.0.0.1",
			port: 7545,
			network_id: "*", // Match any network id
		},
	},
	compilers: {
		solc: {
			version: "0.6.6",
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
};
