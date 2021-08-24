const FlashLoanV2 = artifacts.require("FlashLoanV2");

module.exports = function (deployer) {
	deployer.deploy(FlashLoanV2);
};
