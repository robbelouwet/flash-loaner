const { assert } = require("chai");
const Bot = artifacts.require("Bot");
require("dotenv").config();

require("chai").use(require("chai-as-promised")).should();

contract("Bot", _ => {
    let bot;

    describe("Deployment", async () => {
        it("Bot deployed successfully", async () => {
            bot = await Bot.deployed();
            //console.log(collectible);
            const address = bot.address;
            assert.notEqual(address, "");
            assert.notEqual(address, 0x0);
            assert.notEqual(address, null);
            assert.notEqual(address, undefined);
        });

        it("Loan and pay back", async () => {
            const _tx = await bot.findArbitrage();
            console.log(_tx.tx)
        });
    });
})