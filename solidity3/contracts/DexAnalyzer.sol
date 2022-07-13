// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/Strings.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v3-core/contracts/libraries/LowGasSafeMath.sol";
import {Libs} from "./Structs.sol";
import "./DexHandler.sol";

contract DexAnalyzer {
    using strings for *;

    address _owner;

    DexHandler _dex_handler;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address dex_handler) {
        _owner = msg.sender;
        _dex_handler = DexHandler(dex_handler);
    }

    function analyzeDexes(Libs.FlashCallbackData memory cbdata)
        public
        returns (string memory best_buy_dex, string memory best_sell_dex)
    {
        uint256 amount_out_buy;
        string memory buy_dex;

        uint256 amount_out_sell;
        string memory sell_dex;
    }

    /*
     * Find pool where token_in = token0 is our amount0
     * and where output = token1 = as much as possible
     */
    function getMaxOutPool(
        address token_in,
        address token_out,
        Libs.FlashCallbackData memory cbdata
    ) public returns (uint256 max, string memory max_pool) {
        // uniswap V3, 0.01% fee
        if (cbdata.pair.uniswap_v3_100 != address(0x0)) {
            uint256 am = checkUniswapV3PoolByFee(
                cbdata.pair.token0,
                cbdata.pair.token1,
                cbdata,
                cbdata.pair.uniswap_v3_100,
                100
            );

            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_100" : max_pool;
        }

        // uniswap V3, 0.5% fee
        if (cbdata.pair.uniswap_v3_500 != address(0x0)) {
            uint256 am = checkUniswapV3PoolByFee(
                cbdata.pair.token0,
                cbdata.pair.token1,
                cbdata,
                cbdata.pair.uniswap_v3_500,
                500
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_500" : max_pool;
        }

        // uniswap V3, 0.3% fee
        if (cbdata.pair.uniswap_v3_1000 != address(0x0)) {
            uint256 am = checkUniswapV3PoolByFee(
                cbdata.pair.token0,
                cbdata.pair.token1,
                cbdata,
                cbdata.pair.uniswap_v3_1000,
                1000
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_1000" : max_pool;
        }

        // uniswap V3, 0.3% fee
        if (cbdata.pair.uniswap_v3_3000 != address(0x0)) {
            uint256 am = checkUniswapV3PoolByFee(
                cbdata.pair.token0,
                cbdata.pair.token1,
                cbdata,
                cbdata.pair.uniswap_v3_3000,
                3000
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_3000" : max_pool;
        }

        // uniswap V3, 1% fee
        if (cbdata.pair.uniswap_v3_10000 != address(0x0)) {
            uint256 am = checkUniswapV3PoolByFee(
                cbdata.pair.token0,
                cbdata.pair.token1,
                cbdata,
                cbdata.pair.uniswap_v3_10000,
                10000
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_10000" : max_pool;
        }

        // uniswap V2
        if (cbdata.pair.sushiswap != address(0x0)) {
            uint256 am = checkUniswapV2Pair(
                cbdata.pair.token0,
                cbdata.pair.token1,
                cbdata,
                true
            );
            max = am > max ? am : max;
            max_pool = am > max ? "sushiswap" : max_pool;
        }

        // sushiswap
        if (cbdata.pair.uniswap_v2 != address(0x0)) {
            uint256 am = _dex_handler.uniswapV2AmountOut(
                cbdata,
                token_in,
                token_out,
                cbdata.amount0,
                false,
                true
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v2" : max_pool;
        }
    }

    function checkUniswapV2Pair(
        address token_in,
        address token_out,
        Libs.FlashCallbackData memory cbdata,
        bool sushiswap
    ) internal returns (uint256 amount) {
        uint256 am = _dex_handler.uniswapV2AmountOut(
            cbdata,
            token_in,
            token_out,
            cbdata.amount0,
            false,
            true
        );
    }

    function checkUniswapV3PoolByFee(
        address token_in,
        address token_out,
        Libs.FlashCallbackData memory cbdata,
        address pool,
        uint24 fee
    ) internal returns (uint256 amount) {
        uint256 am;
        try
            _dex_handler.uniswapV3AmountOut(
                cbdata,
                token_in,
                token_out,
                cbdata.amount0,
                fee,
                true
            )
        returns (uint256 _am) {
            am = _am;
        } catch {
            require(
                strEqual(
                    _dex_handler._revert_value_id(),
                    "DexHandler::uniswapV3AmountOut"
                )
            );
            am = abi.decode(_dex_handler._revert_value(), (uint256));
        }
    }

    /*
     * Find pool where input = token1 = our amount
     * Find pool where token_out = token0 is out amount
     */
    function getMinInPool(Libs.FlashCallbackData memory cbdata)
        public
        returns (uint256)
    {}

    function strEqual(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encode(str1)) == keccak256((abi.encode(str2))));
    }
}
