// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/v3-periphery/contracts/libraries/PoolAddress.sol";

library Libs {
    struct Pair {
        address token0;
        address token1;
        address uniswap_v3_100;
        address uniswap_v3_500;
        address uniswap_v3_1000;
        address uniswap_v3_3000;
        address uniswap_v3_10000;
        address uniswap_v2;
        address sushiswap;
    }

    struct Trade {
        int256 profit;
        address token_in;
        address token_out;
        string dex_swap_in;
        string dex_swap_out;
        bool executed;
    }

    struct FlashParams {
        address token0;
        address token1;
        uint24 fee1;
        uint256 amount0;
        uint256 amount1;
    }

    struct FlashCallbackData {
        Pair pair;
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey;
        uint24 poolFee2;
        uint24 poolFee3;
        bool _revert;
    }
}
