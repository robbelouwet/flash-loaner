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
import "./Structs.sol";

contract DexHandler {
    // used to carry over state between a failing require() and entering the catch block
    string public _revert_value_id;
    bytes public _revert_value;

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
        Libs.FlashCallbackData memory cbdata,
        address token_in,
        address token_out,
        uint256 amount_in,
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

        amount = ISwapRouter(_routers["uniswap_v3"]).exactInputSingle(params);
        if (test_revert) {
            _revert_value_id = "DexHandler::uniswapV3AmountOut";
            _revert_value = abi.encode(amount);
            require(1 == 2);
        }
    }

    function uniswapV2AmountOut(
        Libs.FlashCallbackData memory cbdata,
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
            sushiswap ? cbdata.pair.sushiswap : cbdata.pair.uniswap_v2
        );

        uint112 reserve_in;
        uint112 reserve_out;
        uint32 _block;
        (reserve_in, reserve_out, _block) = pair.getReserves();

        amount = r.quote(amount_in, reserve_in, reserve_out);

        if (test_revert) {
            _revert_value_id = "DexHandler::uniswapV2AmountOut";
            _revert_value = abi.encode(amount);
            require(1 == 2);
        }
    }
}
