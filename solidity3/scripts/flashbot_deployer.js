// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3();

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const FlashLoaner = await hre.ethers.getContractFactory("FlashLoaner");
    const flash_loaner = await FlashLoaner.deploy(
        web3.utils.toChecksumAddress('0xE592427A0AEce92De3Edee1F18E0157C05861564'), // SwapRouter, all nets
        web3.utils.toChecksumAddress('0x1F98431c8aD98523631AE4a59f267346ea31F984'), // uniswapV3Factory, all nets
        web3.utils.toChecksumAddress('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'), // WETH, Ropsten


    )
    const deployed_loaner = await flash_loaner.deployed();

    const Bot = await hre.ethers.getContractFactory("Bot");
    const bot = await Bot.deploy(
        deployed_loaner.address
    )
    await bot.deployed()
    console.log("Bot deployed at: ", bot.address);
    console.log("FlashLoaner deployed at: ", flash_loaner.address)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
