const Bot = artifacts.require("Bot.sol");
const FlashLoaner = artifacts.require("FlashLoaner.sol");
const TestPool = artifacts.require("TestPool.sol")

require("dotenv").config();
const Web3 = require("web3");
const web3 = new Web3();

module.exports = (deployer) =>
  deployer.deploy(TestPool).then(_ =>
    deployer.deploy(FlashLoaner,
      web3.utils.toChecksumAddress('0xE592427A0AEce92De3Edee1F18E0157C05861564'), // SwapRouter, all nets
      web3.utils.toChecksumAddress('0x1F98431c8aD98523631AE4a59f267346ea31F984'), // uniswapV3Factory, all nets
      web3.utils.toChecksumAddress('0xc778417E063141139Fce010982780140Aa0cD5Ab'), // WETH, Ropsten

      TestPool.address
    ).then(_ =>
      deployer.deploy(Bot, FlashLoaner.address)));
;
