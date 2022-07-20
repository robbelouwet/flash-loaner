const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs")

const Web3 = require("web3");
const web3 = new Web3();

describe("FlashBot", function () {
    let _bot;
    let _dex_analyzer;
    let _dex_handler;
    let _flash_loaner;

    it("Deploy", async function () {
        // Libs library
        const Libs = await hre.ethers.getContractFactory("Libs");
        const libs = await Libs.deploy()
        const deployed_libs = await libs.deployed()

        // Dex Handler
        const DexHandler = await hre.ethers.getContractFactory("DexHandler");
        const dex_handler = await DexHandler.deploy()
        _dex_handler = await dex_handler.deployed()

        // Dex Analyzer
        const DexAnalyzer = await hre.ethers.getContractFactory("DexAnalyzer",
            {
                libraries: {
                    Libs: deployed_libs.address
                }
            }
        );
        const dex_analyzer = await DexAnalyzer.deploy(_dex_handler.address)
        _dex_analyzer = await dex_analyzer.deployed()

        // Flash Loaner
        const FlashLoaner = await hre.ethers.getContractFactory("FlashLoaner",
            // {
            //     libraries: {
            //         Libs: deployed_libs.address
            //     }
            // }
        );
        const flash_loaner = await FlashLoaner.deploy(
            web3.utils.toChecksumAddress('0xE592427A0AEce92De3Edee1F18E0157C05861564'), // SwapRouter, all nets
            _dex_analyzer.address,
            web3.utils.toChecksumAddress('0x1F98431c8aD98523631AE4a59f267346ea31F984'), // uniswapV3Factory, all nets
            web3.utils.toChecksumAddress('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'), // WETH, Ropsten
        )
        _flash_loaner = await flash_loaner.deployed();

        // Bot
        const Bot = await hre.ethers.getContractFactory("Bot",
            // {
            //     libraries: {
            //         Libs: deployed_libs.address
            //     }
            // }
        );
        const bot = await Bot.deploy(
            _flash_loaner.address
        )
        _bot = await bot.deployed()

        //console.log("Bot deployed at: ", bot.address);
        //console.log("FlashLoaner deployed at: ", flash_loaner.address)
    });

    it("upload common pairs", async () => {

        const pools = JSON.parse(fs.readFileSync("./unduped_commons.json"))

        const _tx = await _bot.saveCommonPairs(pools);

        const res = await _bot.getCommonPairsLength();
        //console.log(res)
    })

    // it("DexHandler test peekUniswapV3Swap", async () => {
    //     const _tx = await _dex_analyzer.peekUniswapV3Swap(
    //         "0x853d955aCEf822Db058eb8505911ED77F175b99e",
    //         "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    //         100,
    //         {
    //             token0: "0x853d955aCEf822Db058eb8505911ED77F175b99e",
    //             token1: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    //             uniswap_v3_100: "0x9A834b70C07C81a9fcD6F22E842BF002fBfFbe4D",
    //             uniswap_v3_500: "0xc63B0708E2F7e69CB8A1df0e1389A98C35A76D52",
    //             uniswap_v3_1000: "0x0000000000000000000000000000000000000000",
    //             uniswap_v3_3000: "0x10581399A549DBfffDbD9B070a0bA2f9F61620D2",
    //             uniswap_v3_10000: "0x0000000000000000000000000000000000000000",
    //             uniswap_v2: "0x97C4adc5d28A86f9470C70DD91Dc6CC2f20d2d4D",
    //             sushiswap: "0x0000000000000000000000000000000000000000"
    //         },
    //         100
    //     )
    //     await _tx.wait();
    // })

    it("Integration test", async () => {
        await _bot.start()
    })
});
