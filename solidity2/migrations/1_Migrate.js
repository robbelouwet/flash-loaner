const DexAnalyzer = artifacts.require("DexAnalyzer.sol");
const Bot = artifacts.require("Bot.sol");

module.exports = function (deployer) {
  deployer.deploy(DexAnalyzer);
};
