const Arbitrage = artifacts.require("Arbitrage");

module.exports = function (deployer) {
	deployer.deploy(
		Arbitrage,
		"0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73", // PancakeFactory address
		"0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F"
	);
};
