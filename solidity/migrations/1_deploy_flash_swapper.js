const Arbitrage = artifacts.require("Arbitrage");

module.exports = function (deployer) {
	// pancakefactory: 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73

	deployer.deploy(Arbitrage);
};
