// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "./DexHandler.sol";
import "hardhat/console.sol";
import "./Structs.sol";

contract DexAnalyzer {
    address _owner;

    DexHandler _dex_handler;
    FlashLoaner _flash_loaner;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address dex_handler, address flash_loaner) {
        _flash_loaner = flash_loaner;

        _owner = msg.sender;
        _dex_handler = DexHandler(dex_handler);
    }

    function analyzeDexes(Structs.FlashCallbackData memory cbdata)
        public
        returns (
            string memory best_buy_dex,
            string memory best_sell_dex,
            int256 profit_token0
        )
    {
        // ---> token0 --->
        //                  buy_dex?
        // <--- token1 <---
        uint256 amount_out_buy;
        string memory buy_dex;
        (amount_out_buy, buy_dex) = getMaxOutPool(
            cbdata.pair.token0,
            cbdata.pair.token1,
            cbdata.amount0,
            cbdata.pair
        );

        // ---> token1 --->
        //                  sell_dex
        // <--- token0 <---
        uint256 amount_out_sell;
        string memory sell_dex;
        (amount_out_sell, sell_dex) = getMaxOutPool(
            cbdata.pair.token1,
            cbdata.pair.token0,
            amount_out_buy,
            cbdata.pair
        );

        profit_token0 = amount_out_sell - cbdata.amount0;
        // make token0 delta profit amount
        // is this amount great enough to surpass costs and fees?
    }

    /*
     * Find pool where token_in = token0 is our amount0
     * and where output = token1 = as much as possible
     */
    function getMaxOutPool(
        address token_in,
        address token_out,
        uint256 amount_in,
        Structs.Pair memory pair
    ) public returns (uint256 max, string memory max_pool) {
        // uniswap V3, 0.01% fee
        if (pair.uniswap_v3_100 != address(0x0)) {
            uint256 am = peekUniswapV3Swap(
                token_in,
                token_out,
                amount_in,
                pair,
                100
            );

            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_100" : max_pool;
        }

        // uniswap V3, 0.5% fee
        if (pair.uniswap_v3_500 != address(0x0)) {
            uint256 am = peekUniswapV3Swap(
                token_in,
                token_out,
                amount_in,
                pair,
                500
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_500" : max_pool;
        }

        // uniswap V3, 0.3% fee
        if (pair.uniswap_v3_1000 != address(0x0)) {
            uint256 am = peekUniswapV3Swap(
                token_in,
                token_out,
                amount_in,
                pair,
                1000
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_1000" : max_pool;
        }

        // uniswap V3, 0.3% fee
        if (pair.uniswap_v3_3000 != address(0x0)) {
            uint256 am = peekUniswapV3Swap(
                token_in,
                token_out,
                amount_in,
                pair,
                3000
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_3000" : max_pool;
        }

        // uniswap V3, 1% fee
        if (pair.uniswap_v3_10000 != address(0x0)) {
            uint256 am = peekUniswapV3Swap(
                token_in,
                token_out,
                amount_in,
                pair,
                10000
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v3_10000" : max_pool;
        }

        // uniswap V2
        if (pair.sushiswap != address(0x0)) {
            uint256 am = peekUniswapV2Swap(
                token_in,
                token_out,
                amount_in,
                pair,
                true
            );
            max = am > max ? am : max;
            max_pool = am > max ? "sushiswap" : max_pool;
        }

        // sushiswap
        if (pair.uniswap_v2 != address(0x0)) {
            uint256 am = peekUniswapV2Swap(
                token_in,
                token_out,
                amount_in,
                pair,
                false
            );
            max = am > max ? am : max;
            max_pool = am > max ? "uniswap_v2" : max_pool;
        }
    }

    function peekUniswapV2Swap(
        address token_in,
        address token_out,
        uint256 amount_in,
        Structs.Pair memory pair,
        bool sushiswap
    ) internal returns (uint256 amount) {
        try
            _dex_handler.uniswapV2AmountOut(
                pair,
                token_in,
                token_out,
                amount_in,
                sushiswap, // sushiswap?
                true // testmode?
            )
        returns (uint256 _am) {
            amount = _am;
        } catch (bytes memory b) {
            amount = abi.decode(b, (uint256));
        }
    }

    function peekUniswapV3Swap(
        address token_in,
        address token_out,
        uint256 amount_in,
        Structs.Pair memory pair,
        uint24 fee
    ) public returns (uint256 amount) {
        try
            _dex_handler.uniswapV3AmountOut(
                token_in,
                token_out,
                amount_in,
                pair,
                fee,
                true // testmode?
            )
        returns (uint256 _am) {
            amount = _am;
            console.log("Try successfull: %d", amount);
        } catch (bytes memory b) {
            if (!matchError("TradeResult(uint256)", b)) rethrow();
            bytes memory stripped = stripSelector(b);
            amount = abi.decode(stripped, (uint256));

            console.log("Catch executed, amount: %d", amount);
        }
    }

    function strEqual(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encode(str1)) == keccak256((abi.encode(str2))));
    }

    function rethrow() public pure {
        // rethrow a caught Error
        assembly {
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }

    function matchError(string memory str, bytes memory b2)
        internal
        view
        returns (bool)
    {
        bytes memory strBytes = abi.encodePacked(keccak256(bytes(str)));

        bytes memory b1_cropped = substring(strBytes, 0, 4);
        bytes memory b2_cropped = substring(b2, 0, 4);

        return keccak256(b1_cropped) == keccak256(b2_cropped);
    }

    function substring(
        bytes memory strBytes,
        uint256 startIndex,
        uint256 endIndex
    ) internal view returns (bytes memory) {
        bytes memory result = new bytes(endIndex - startIndex);

        for (uint256 i = startIndex; i < endIndex; i++)
            result[i - startIndex] = strBytes[i];

        return result;
    }

    function stripSelector(bytes memory b)
        internal
        view
        returns (bytes memory res)
    {
        res = substring(b, 4, b.length);
    }
}
