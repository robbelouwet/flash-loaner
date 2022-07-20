// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
pragma abicoder v2;

import "../libs/Strings.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "./Libs.sol";
import "hardhat/console.sol";

/// Reports the result of a reverted swap() call because it ran in 'test mode'
/// @param amount the amount of tokens we would've gotton back from this trade
error TradeResult(uint256 amount);

contract DexHandler {
    function uniswapV3AmountOut(
        address token_in,
        address token_out,
        uint256 amount_in,
        Libs.Pair memory pair,
        uint24 fee,
        bool test_revert
    ) external returns (uint256 amount) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token_in,
                tokenOut: token_out,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: amount_in,
                amountOutMinimum: LowGasSafeMath.add(amount_in, fee),
                sqrtPriceLimitX96: 0
            });
        amount = Libs.getUniswapV3Router().exactInputSingle(params);

        printV3SwapSummary(
            params.tokenIn,
            params.tokenOut,
            params.amountIn,
            params.fee,
            pair,
            amount
        );

        if (test_revert) revert TradeResult(amount);
    }

    function uniswapV2AmountOut(
        Libs.Pair memory pair,
        address token_in,
        address token_out,
        uint256 amount_in,
        bool sushiswap,
        bool test_revert
    ) external returns (uint256 amount) {
        IUniswapV2Router02 r = sushiswap
            ? Libs.getUniswapV2Router()
            : Libs.getSushiswapRouter();

        IUniswapV2Pair pair = IUniswapV2Pair(
            sushiswap ? pair.sushiswap : pair.uniswap_v2
        );

        uint112 reserve_in;
        uint112 reserve_out;
        uint32 _block;
        (reserve_in, reserve_out, _block) = pair.getReserves();

        amount = r.quote(amount_in, reserve_in, reserve_out);

        if (test_revert) revert TradeResult(amount);
    }

    function printV3SwapSummary(
        address token_in,
        address token_out,
        uint256 amount_in,
        uint24 fee,
        Libs.Pair memory pair,
        uint256 amount
    ) internal {
        console.log("IN:\t%d x %s", amount_in, token_in);
        console.log("OUT:\t%d x %s\nFEE:\t%d", amount, token_out, fee);
    }
}
