const { expect } = require("chai");
const { ethers } = require("hardhat");
const fs = require("fs")

const Web3 = require("web3");
const web3 = new Web3();

describe("Test", () => {
    it("IDK", async () => {
        const Test = await hre.ethers.getContractFactory("Test");
        await Test.deploy()
    })
});
