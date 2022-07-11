// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "../libs/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../libs/v3-core/contracts/libraries/LowGasSafeMath.sol";

import "../libs/v3-periphery/contracts/base/PeripheryPayments.sol";
import "../libs/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "../libs/v3-periphery/contracts/libraries/PoolAddress.sol";
import "../libs/CallbackValidation.sol";
import "../libs/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract FlashLoaner is IUniswapV3FlashCallback, PeripheryPayments {
    address _owner;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    struct FlashParams {
        address token0;
        address token1;
        uint24 fee1;
        uint256 amount0;
        uint256 amount1;
    }

    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey;
        uint24 poolFee2;
        uint24 poolFee3;
    }

    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    // uniswap V3 router
    ISwapRouter _swap_router;

    constructor(
        ISwapRouter _swapRouter,
        address _factory,
        address _WETH9
    ) PeripheryImmutableState(_factory, _WETH9) {
        _swap_router = ISwapRouter(_swapRouter);
        _owner = msg.sender;
    }

    function internalCallback() internal {
        // find the best buy and sell dexes for the specified pair
        for (uint256 i = 0; i < _common_pairs.length; i++) {
            string memory best_buy_dex;
            string memory best_sell_dex;

            (best_buy_dex, best_sell_dex) = _dex_analyzer.analyzeDexes(
                calculateOptimalAmountIn(_common_pairs[i]),
                _common_pairs[i].token0,
                _common_pairs[i].token1
            );
        }
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        internalCallback();
        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );
        CallbackValidation.verifyCallback(factory, decoded.poolKey);

        address token0 = decoded.poolKey.token0;
        address token1 = decoded.poolKey.token1;

        TransferHelper.safeApprove(
            token0,
            address(_swap_router),
            decoded.amount0
        );
        // TransferHelper.safeApprove(
        //     token1,
        //     address(_swap_router),
        //     decoded.amount1
        // );

        // profitable check
        // exactInputSingle will fail if this amount not met
        uint256 amount0Min = LowGasSafeMath.add(decoded.amount0, fee0);
        //uint256 amount1Min = LowGasSafeMath.add(decoded.amount1, fee1);

        // call exactInputSingle for swapping token1 for token0 in pool w/fee2
        uint256 amountOut0 = _swap_router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token0,
                fee: decoded.poolFee2,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: decoded.amount1,
                amountOutMinimum: amount0Min,
                sqrtPriceLimitX96: 0
            })
        );
        /*
        // call exactInputSingle for swapping token0 for token 1 in pool w/fee3
        uint256 amountOut1 = _swap_router.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token0,
                tokenOut: token1,
                fee: decoded.poolFee3,
                recipient: address(this),
                deadline: block.timestamp + 200,
                amountIn: decoded.amount0,
                amountOutMinimum: amount1Min,
                sqrtPriceLimitX96: 0
            })
        );

        // end up with amountOut0 of token0 from first swap and amountOut1 of token1 from second swap
        uint256 amount0Owed = LowGasSafeMath.add(decoded.amount0, fee0);
        uint256 amount1Owed = LowGasSafeMath.add(decoded.amount1, fee1);

        TransferHelper.safeApprove(token0, address(this), amount0Owed);
        TransferHelper.safeApprove(token1, address(this), amount1Owed);

        if (amount0Owed > 0)
            pay(token0, address(this), msg.sender, amount0Owed);
        if (amount1Owed > 0)
            pay(token1, address(this), msg.sender, amount1Owed);

        // if profitable pay profits to payer
        if (amountOut0 > amount0Owed) {
            uint256 profit0 = LowGasSafeMath.sub(amountOut0, amount0Owed);

            TransferHelper.safeApprove(token0, address(this), profit0);
            pay(token0, address(this), decoded.payer, profit0);
        }
        if (amountOut1 > amount1Owed) {
            uint256 profit1 = LowGasSafeMath.sub(amountOut1, amount1Owed);
            TransferHelper.safeApprove(token0, address(this), profit1);
            pay(token1, address(this), decoded.payer, profit1);
        }*/
    }
}
