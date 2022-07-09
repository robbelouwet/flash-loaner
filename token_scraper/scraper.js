require("dotenv").config();
const hre = require("hardhat");
const fs = require("fs")
const Web3 = require("web3");
const { exit } = require("process");
const web3 = new Web3(`https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`);

const scrapev2 = async (dex) => {
    const fact_abi = JSON.parse(fs.readFileSync("./abis/UniswapV2Factory.json"))
    const pair_abi = JSON.parse(fs.readFileSync("./abis/UniswapV2Pair.json"))

    const factory = new web3.eth.Contract(fact_abi, web3.utils.toChecksumAddress("0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"))
    const allPairsLength = await factory.methods.allPairsLength().call()

    const v2_struct = {}

    for (let i = 0; i < allPairsLength; i++) {
        const poolAdr = await factory.methods.allPairs(i).call()

        console.log(`${i}/${allPairsLength}: Scraping ${poolAdr}`)

        const pool = new web3.eth.Contract(pair_abi, poolAdr)

        const token0 = await pool.methods.token0().call();
        const token1 = await pool.methods.token1().call()

        v2_struct[poolAdr] = {
            "token0": token0,
            "token1": token1
        }
    }

    fs.writeFileSync(`./pools/${dex}.json`, JSON.stringify(v2_struct))

}

const makeBetter = async (poolAdr, dict) => {
    const v3_pool_abi = JSON.parse(fs.readFileSync("./node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Pool.sol/UniswapV3Pool.json"))["abi"];
    //console.log(v3_pool_abi)
    const v2_erc20_abi = JSON.parse(fs.readFileSync("./artifacts/contracts/ERC20.sol/ERC20.json"))["abi"];
    //console.log(v2_erc20_abi)

    const pool = new web3.eth.Contract(v3_pool_abi, poolAdr)
    const fee = await pool.methods.fee().call();
    console.log(fee)

    const token0_adr = await pool.methods.token0().call()

    const token1_adr = await pool.methods.token1().call()

    dict[`${poolAdr}`] = {
        "fee": fee,
        "token0": token0_adr,
        "token1": token1_adr,
    }

}

const scrape = async (data) => {
    pools = JSON.parse(data)

    let better_pools = {}

    for (let i = 0; i < pools.length; await makeBetter(pools[i++], better_pools))

        fs.writeFile("./better_pools.json", JSON.stringify(better_pools), (s) => null)

}

const main = async () => {
    await findCommonPairs()
}

const main2 = async () => {
    const factory = await getFactory();
    const poolsLength = (await factory.allPairsLength())
    let uniswap_tokens = {}

    for (let i = 0; i < poolsLength; i++) {
        const poolAddr = await factory.allPairs(i);
        const Pool = await hre.ethers.getContractFactory("UniswapV2Pair");
        const pool = await Pool.attach(poolAddr);

        const ERC20 = await hre.ethers.getContractFactory("UniswapV2ERC20");

        const token0 = await ERC20.attach(await pool.token0())
        const symbol0 = await token0.symbol()

        const token1 = await ERC20.attach(await pool.token1())
        const symbol1 = await token1.symbol()

        console.log(`${i}/${poolsLength}: Fetching ${symbol0}-${symbol1}`)

        uniswap_tokens[`${symbol0}-${symbol1}`] = {
            "addr": poolAddr,
            "token0": token0.address,
            "token1": token1.address,
        }
    }

    await fs.writeFile("./uniswap_tokens.json", JSON.stringify(uniswap_tokens), (s) => null)
}

const findCommonPairs = async () => {
    const v2_factory = getUniswapV2Factory()
    const v3_factory = getUniswapV3Factory()
    const sushi_factory = getSushiSwapFactory()

    const uniswap_v3_pools = JSON.parse(fs.readFileSync("./pools/uniswap_v3/popular_pools.json"))

    let all_common_pairs = {}

    let counter = 0
    for (const [uniswap_v3_pool, value] of Object.entries(uniswap_v3_pools)) {
        console.log(`Comparing ${value.token0}-${value.token1}`)
        if (counter >= 50) break
        counter++

        let common_pairs = {}
        // see if uniswap V3 has a pool for this pair
        // returns [...[pool_adr, fee]...] (multiple pools because of fee tiers)
        const v3_pools = await hasV3Pool(value, v3_factory)

        v3_pools.forEach(pool => {
            if (common_pairs["uniswap_v3"] == undefined)
                common_pairs["uniswap_v3"] = {}
            common_pairs["uniswap_v3"][pool[1]] = pool[0]
        }

        );

        // see if uniswap V2 has this pair
        const v2_pair = await hasV2Pair(value, v2_factory)
        if (v2_pair != undefined) {
            common_pairs["uniswap_v2"] = v2_pair
        }

        // see if sushiswap has this pair
        const sushi_pair = await hasV2Pair(value, sushi_factory)
        if (v2_pair != undefined) {
            common_pairs["sushiswap"] = sushi_pair
        }

        all_common_pairs[`${value.token0}-${value.token1}`] = common_pairs

    }

    fs.writeFileSync("./pools/common.json", JSON.stringify(all_common_pairs))
}

const hasV2Pair = async (value, v2_factory) => {
    const pair_adr = await v2_factory.methods.getPair(
        web3.utils.toChecksumAddress(value["token0"]),
        web3.utils.toChecksumAddress(value["token1"]),
    ).call()

    return !web3.utils.toBN(pair_adr).isZero() ?
        pair_adr :
        undefined
}

const hasV3Pool = async (value, v3_factory) => {

    let v3_pools = [];
    for (fee of [100, 3000, 5000]) {
        const pool_adr = await v3_factory.methods.getPool(
            web3.utils.toChecksumAddress(value["token0"]),
            web3.utils.toChecksumAddress(value["token1"]),
            fee
        ).call()


        if (!web3.utils.toBN(pool_adr).isZero()) {
            v3_pools.push([pool_adr, fee])
        }
    }

    return v3_pools
}

const getUniswapV3Factory = () => {
    const abi = JSON.parse(fs.readFileSync("./node_modules/@uniswap/v3-core/artifacts/contracts/UniswapV3Factory.sol/UniswapV3Factory.json"))["abi"]
    return new web3.eth.Contract(abi, web3.utils.toChecksumAddress("0x1F98431c8aD98523631AE4a59f267346ea31F984"))
}

const getUniswapV2Factory = () => {
    const abi = JSON.parse(fs.readFileSync("./abis/UniswapV2Factory.json"))
    return new web3.eth.Contract(abi, web3.utils.toChecksumAddress("0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"))
}

const getSushiSwapFactory = () => {
    const abi = JSON.parse(fs.readFileSync("./abis/UniswapV2Factory.json"))
    return new web3.eth.Contract(abi, web3.utils.toChecksumAddress("0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac"))
}

main()