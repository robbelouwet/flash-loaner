const { assert } = require("chai");
const DexAnalyzer = artifacts.require("DexAnalyzer");
require("dotenv").config();

require("chai").use(require("chai-as-promised")).should();

contract("DexAnalyzer", _ => {
    let analyzer;

    describe("Deployment", async () => {
        it("DexAnalyzer deployed successfully", async () => {
            analyzer = await DexAnalyzer.deployed();
            //console.log(collectible);
            const address = analyzer.address;
            assert.notEqual(address, "");
            assert.notEqual(address, 0x0);
            assert.notEqual(address, null);
            assert.notEqual(address, undefined);
        });
    });
})