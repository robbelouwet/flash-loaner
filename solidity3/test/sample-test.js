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

        const pools = JSON.parse(fs.readFileSync("./unduped_common.json"))

        const _tx = await dexAnalyzer.saveCommonPairs(pools);

        const res = await dexAnalyzer.getCommonPairsLength();
        console.log(res)
    })

    it("DexHandler test", async () => {
        const DexHandler = await hre.ethers.getContractFactory("DexHandler");
        const dex_handler = await DexHandler.deploy()

        //console.log("DexHandler at: ", dex_handler.address);

        const DexAnalyzer = await hre.ethers.getContractFactory("contracts2/DexAnalyzer.sol:DexAnalyzer");
        const dex_analyzer = await DexAnalyzer.deploy(
            web3.utils.toChecksumAddress(dex_handler.address)
        )
        await dex_analyzer.deployed()

        //console.log("DexAnalyzer at: ", dex_analyzer.address)

        const _tx = await dex_analyzer.peekUniswapV3Swap(
            "0x853d955aCEf822Db058eb8505911ED77F175b99e",
            "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
            100,
            {
                token0: "0x853d955aCEf822Db058eb8505911ED77F175b99e",
                token1: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                uniswap_v3_100: "0x9A834b70C07C81a9fcD6F22E842BF002fBfFbe4D",
                uniswap_v3_500: "0xc63B0708E2F7e69CB8A1df0e1389A98C35A76D52",
                uniswap_v3_1000: "0x0000000000000000000000000000000000000000",
                uniswap_v3_3000: "0x10581399A549DBfffDbD9B070a0bA2f9F61620D2",
                uniswap_v3_10000: "0x0000000000000000000000000000000000000000",
                uniswap_v2: "0x97C4adc5d28A86f9470C70DD91Dc6CC2f20d2d4D",
                sushiswap: "0x0000000000000000000000000000000000000000"
            },
            100
        )
        await _tx.wait();
    })
});
