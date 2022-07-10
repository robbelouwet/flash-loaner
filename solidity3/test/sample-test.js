const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs")

const Web3 = require("web3");
const web3 = new Web3();

describe("FlashBot", function () {
    let bot;
    let dexAnalyzer;
    it("Deployed Bot", async function () {
        const FlashLoaner = await hre.ethers.getContractFactory("FlashLoaner");
        const flash_loaner = await FlashLoaner.deploy(
            web3.utils.toChecksumAddress('0xE592427A0AEce92De3Edee1F18E0157C05861564'), // SwapRouter, all nets
            web3.utils.toChecksumAddress('0x1F98431c8aD98523631AE4a59f267346ea31F984'), // uniswapV3Factory, all nets
            web3.utils.toChecksumAddress('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'), // WETH, Ropsten


        )
        const deployed_loaner = await flash_loaner.deployed();

        const Bot = await hre.ethers.getContractFactory("Bot");
        bot = await Bot.deploy(
            deployed_loaner.address
        )
        await bot.deployed()

        console.log("Bot deployed at: ", bot.address);
        console.log("FlashLoaner deployed at: ", flash_loaner.address)
    });

    it("Loan and pay back", async () => {
        const _tx = await bot.findArbitrage();
        console.log(_tx.tx)
    });

    it("Deployed DexAnalyzer", async () => {
        const DexAnalyzer = await hre.ethers.getContractFactory("DexAnalyzer");
        dexAnalyzer = await DexAnalyzer.deploy()
    })

    it("Common pairs", async () => {
        const DexAnalyzer = await hre.ethers.getContractFactory("DexAnalyzer");
        dexAnalyzer = await DexAnalyzer.deploy()

        const pools = JSON.parse(fs.readFileSync("./common.json"))

        const _tx = await dexAnalyzer.saveCommonPairs(pools);

        const res = await dexAnalyzer.getCommonPairsLength();
        console.log(res)
    })
});
