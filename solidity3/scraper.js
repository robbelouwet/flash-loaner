require("dotenv").config();
const hre = require("hardhat");
const Web3 = require("web3");
const web3 = new Web3(`https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`);

const main = async () => {
    await hre.run('compile');

    hre.ethers.getContractFactory("UniswapV2Router02").then(i => console.log(i)).catch(i => console.error(i));
    console.log(router)
}

main()