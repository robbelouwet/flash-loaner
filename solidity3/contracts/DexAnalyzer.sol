// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7;
pragma abicoder v2;

import "./libs/Strings.sol";

import "./libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./libs/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./libs/v2-periphery/contracts/UniswapV2Router02.sol";
import "./libs/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./libs/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./libs/PairLibs.sol";

contract DexAnalyzer {
    using StringUtils for *;

    address _owner;

    // routers
    string[] _routers_ids;
    mapping(string => address) public _routers;

    // quoters
    string[] _quoters_ids;
    mapping(string => address) public _quoters;

    Pool[] _common_pools;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;

        // === ROUTERS ===
        _routers_ids.push("uniswap");
        _routers["uniswap"] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        _routers_ids.push("sushiswap");
        _routers["sushiswap"] = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

        // === QUOTERS ===
        _quoters_ids.push("uniswap");
        _quoters["uniswap"] = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    }

    function saveCommonPairs(Pool[] memory pools) {
        for (uint256 i = 0; i < pools.length; i++) {
            _common.pools.push(pools[i]);
        }
    }

    function analyzeDexes(
        uint256 amount_in,
        address token_in,
        address token_out
    ) public returns (address best_buy_dex, address best_sell_dex) {
        // keep track of the best arb opportunity
        // while analyzing dexes
        uint256 highest_amount_out = 0;
        uint256 lowest_amount_out = 2**255; // some amount close to 'inf'

        for (uint256 i = 0; i < _quoters_ids.length; i++) {
            // the juicy boi (not gas efficient):
            uint256 am = getArbAmountOut(
                amount_in,
                token_in,
                token_out,
                dex_id
            );
            // is this a good buy DEX? Give little t_in, receive alot t_out?
            if (am > highest_amount_out) {
                highest_amount_out = am;
                best_buy_dex = _routers[_routers_ids[i]];
            }

            // is this a good sell DEX? Sell little t_out, get alot of t_in
            if (am < lowest_amount_out) {
                lowest_amount_out = am;
                best_sell_dex = _routers[_routers_ids[i]];
            }
        }
    }

    function getArbAmountOut(
        uint256 amount_in,
        address token_in,
        address token_out,
        string dex_id
    ) returns (uint256) {
        if (dex_id == "uniswap")
            return
                IQuoter(_quoters[_quoters_ids[i]]).quoteExactInputSingle(
                    token_in,
                    token_out,
                    100, // fee, 0.1 %
                    amount_in,
                    0
                );
        if (dex_id == "sushiswap") {
            UniswapV2Router02 router = UniswapV2Router02(_routers[dex_id]);
            address pool = IUniswapV2Factory(
                UniswapV2Router02(_routers[dex_id]).factory
            ).getPair(token_in, token_out);

            uint112 _reserve0;
            uint112 _reserve1;
            uint32 _blockTimestampLast;

            (_reserve0, _reserve1, _blockTimestampLast) = IUniswapV2Pair(pool)
                .getReserves();

            return router.getAmountOut(amount_in, _reserve0, _reserve1);
        }
    }
}
