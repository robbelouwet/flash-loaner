require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs")
const Web3 = require("web3");
const web3 = new Web3(`https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`);

const main = async () => {
    await scrapDuplicates();
}

const scrapDuplicates = async () => {
    let pairsSet = []

    const pairs = JSON.parse(fs.readFileSync("./common.json"))

    for (let i = 0; i < pairs.length; i++) {
        const pair = pairs[i];
        let dupe = false;

        for (let j = 0; j < pairsSet.length; j++) {
            const setPair = pairsSet[j];
            //console.log(`pair1:\n\ttoken0 (${i}): ${pair.token0}\n\ttoken1: ${pair.token1}`)
            //console.log(`pair2:\n\ttoken0 (${j}): ${setPair.token0}\n\ttoken1: ${setPair.token1}`

            if (pair["token0"] === setPair["token0"] &&
                pair["token1"] === setPair["token1"]) {
                dupe = true;
            }

            if (dupe && i === j) {
                console.log(`False positive: i: ${i}, j:${j}\npair: ${JSON.stringify(pair, null, 2)}\nsetPair: ${JSON.stringify(setPair, null, 2)}`)
            }
        }

        if (!dupe) {
            const res = more_than_2(pair)
            if (res != undefined) {
                //console.log(res)
                pairsSet.push(res)
            }
        }
        else console.log("found dupe")

    }

    fs.writeFileSync("./unduped_commons.json", JSON.stringify(pairsSet))
}

const more_than_2 = (pair) => {
    let hits = 0;

    for (const [key, value] of Object.entries(pair)) {
        if (key === "token0" || key === "token1") continue
        else if (!web3.utils.toBN(value).isZero())
            hits++;
    }
    if (hits >= 2)
        return pair
    else return undefined
}

main()