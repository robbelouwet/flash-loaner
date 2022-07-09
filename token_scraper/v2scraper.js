require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs")
const Web3 = require("web3");
const web3 = new Web3(`https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`);

const main = async (dex) => {
    await scrapev2(dex)
}



main("uniswap_v2")