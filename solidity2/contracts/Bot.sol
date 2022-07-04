// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7;
pragma abicoder v2;

import {DexAnalyzer} from "./DexAnalyzer.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-periphery/contracts/base/PeripheryPayments.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";

contract Bot is IUniswapV3FlashCallback, PeripheryPayments {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    // contract owner
    address _owner;
    DexAnalyzer _dex_analyzer;

    // the uniswap with largest liquidity: usdc (105mil) <-> usdt (33mil)
    address _flash_pool = 0x3416cF6C708Da44DB2624D63ea0AAef7113527C6;

    // array of (token0, token1) token pairs present on at least 2 of our DEX's
    address[][2] _pools;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    //=========================================================================
    // - hoe deze params invullen? https://docs.uniswap.org/protocol/guides/flash-integrations/calling-flash
    // - deploy en doe test run
    // - debug: kan em al amount_out terug geven en vinden?
    constructor(
        address dex_analyzer,
        ISwapRouter _swapRouter,
        address _factory,
        address _WETH9
    ) PeripheryImmutableState(_factory, _WETH9) {
        _dex_analyzer = DexAnalyzer(dex_analyzer);
        _owner = msg.sender;
    }

    //=========================================================================

    function findArbitrage()
        public
        isOwner
        returns (
            address token_in_loan,
            address token_out,
            address dex_buy,
            address dex_sell
        )
    {
        // 1 mil
        uint256 amount_in = 1000000 * (10**18);

        // find the best buy and sell dexes for the specified pair
        for (uint256 i = 0; i < _pools.length; i++) {
            address best_buy_dex;
            address best_sell_dex;

            (best_buy_dex, best_sell_dex) = _dex_analyzer.analyzeDexes(
                amount_in,
                _pools[i][0],
                _pools[i][1]
            );
        }
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {}
}
