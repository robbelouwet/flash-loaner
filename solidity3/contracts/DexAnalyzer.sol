// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/Strings.sol";

import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v3-periphery/contracts/interfaces/IQuoter.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {Libs} from "../libs/PairLibs.sol";

contract DexAnalyzer {
    using strings for *;

    address _owner;

    // name of the dexes: uniswap_v3, uniswap_v2, sushiswap
    string[] _dex_ids;

    // a list of Libs.Pool structs the signify a pair of ERC20 tokens available to swap on which DEX's
    Libs.Pool[] _common_pools;

    // routers
    mapping(string => address) public _routers;

    address _uniswap_v3_quoter;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;

        _dex_ids.push("uniswap_v3");
        _dex_ids.push("sushiswap");
        _dex_ids.push("uniswap_v2");

        _routers["uniswap_v3"] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        _routers["uniswap_v2"] = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _routers["sushiswap"] = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

        _uniswap_v3_quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    }

    function saveCommonPairs(Libs.Pool[] memory pools) public {
        for (uint256 i = 0; i < pools.length; i++) {
            _common_pools.push(pools[i]);
        }
    }

    function analyzeDexes(
        uint256 amount_in,
        address token_in,
        address token_out
    ) public returns (string memory best_buy_dex, string memory best_sell_dex) {
        // keep track of the best arb opportunity
        // while analyzing dexes
        uint256 highest_amount_out = 0;
        uint256 lowest_amount_out = 2**255; // some amount close to 'inf'

        for (uint256 i = 0; i < _dex_ids.length; i++) {
            // the juicy boi (not gas efficient):
            uint256 am = getArbAmountOut(
                amount_in,
                token_in,
                token_out,
                _dex_ids[i]
            );
            // is this a good buy DEX? Give little t_in, receive alot t_out?
            if (am > highest_amount_out) {
                highest_amount_out = am;
                best_buy_dex = _dex_ids[i];
            }

            // is this a good sell DEX? Sell little t_out, get alot of t_in
            if (am < lowest_amount_out) {
                lowest_amount_out = am;
                best_sell_dex = _dex_ids[i];
            }
        }
    }

    function getArbAmountOut(
        uint256 amount_in,
        address token_in,
        address token_out,
        string memory dex_id
    ) public returns (uint256) {
        if (
            keccak256(abi.encodePacked(dex_id)) ==
            keccak256(abi.encodePacked("uniswap"))
        )
            return
                IQuoter(_uniswap_v3_quoter).quoteExactInputSingle(
                    token_in,
                    token_out,
                    100, // fee, 0.1 %
                    amount_in,
                    0
                );
        if (
            keccak256(abi.encodePacked(dex_id)) ==
            keccak256(abi.encodePacked("sushiswap"))
        ) {
            IUniswapV2Router02 router = IUniswapV2Router02(_routers[dex_id]);
            address pool = IUniswapV2Factory(
                IUniswapV2Router02(_routers[dex_id]).factory()
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
