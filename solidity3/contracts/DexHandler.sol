// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
pragma abicoder v2;

import "../libs/Strings.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "./Libs.sol";

/// Reports the result of a reverted swap() call because it ran in 'test mode'
/// @param amount the amount of tokens we would've gotton back from this trade
error TradeResult(uint256 amount);

contract DexHandler {
    // name of the dexes: uniswap_v3, uniswap_v2, sushiswap
    string[] _dex_ids;

    // routers
    mapping(string => address) public _routers;

    constructor() {
        _dex_ids.push("uniswap_v3");
        _dex_ids.push("sushiswap");
        _dex_ids.push("uniswap_v2");

        _routers["uniswap_v3"] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        _routers["uniswap_v2"] = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _routers["sushiswap"] = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    }

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

        amount = 1005; //amount = ISwapRouter(_routers["uniswap_v3"]).exactInputSingle(params);
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
        IUniswapV2Router02 r = IUniswapV2Router02(
            _routers[sushiswap ? "sushiswap" : "uniswap_v2"]
        );

        IUniswapV2Pair pair = IUniswapV2Pair(
            sushiswap ? pair.sushiswap : pair.uniswap_v2
        );

        uint112 reserve_in;
        uint112 reserve_out;
        uint32 _block;
        (reserve_in, reserve_out, _block) = pair.getReserves();

        amount = 1003; //amount = r.quote(amount_in, reserve_in, reserve_out);

        if (test_revert) revert TradeResult(amount);
    }
}
