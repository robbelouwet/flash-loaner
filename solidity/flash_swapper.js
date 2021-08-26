const testnet = true;

const Web3 = require("web3");
const address = fs.readFileSync("latest_test_contract.txt");
console.log(address);

(async function () {
	const fs = require("fs");

	const abi = JSON.parse(
		fs.readFileSync(`./build/contracts/Arbitrage.json`)
	).abi;

	const web3 = new Web3(
		testnet
			? `https://data-seed-prebsc-1-s1.binance.org:8545`
			: `https://bsc-dataseed1.binance.org`
	);

	const contract = new web3.eth.Contract(
		abi,
		"0x71dd7f9B5390278a53CA023075D4F34546212D51"
	);

	const result = await contract.methods
		.startArbitrage(
			"0xb67b531bec897b7273b7bb0b3a3bffbdf2ec1905", //FLEX token
			"0x78867bbeef44f2326bf8ddd1941a4439382ef2a7", // BUSD
			1,
			0
		)
		.call();

	console.log(result);
})();
