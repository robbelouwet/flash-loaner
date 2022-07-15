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
import "./DexAnalyzer.sol";
import "./Structs.sol";

contract FlashLoaner is IUniswapV3FlashCallback, PeripheryPayments {
    address _owner;

    DexAnalyzer _dex_analyzer;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    // uniswap V3 router
    ISwapRouter _swap_router;

    constructor(
        ISwapRouter _swapRouter,
        address dex_analyzer,
        address _factory,
        address _WETH9
    ) PeripheryImmutableState(_factory, _WETH9) {
        _dex_analyzer = DexAnalyzer(dex_analyzer);
        _swap_router = ISwapRouter(_swapRouter);
        _owner = msg.sender;
    }

    /// Analyze a given pair of ERC20 tokens, and see if there's an arbitrage opportunity
    /// among our known DEX's.
    ///
    /// performs a swap. If specified, fails on purpose in order to revert and see if the trade would have been profitable
    function analyzePair(Libs.Pair memory pair, bool __revert) public {
        address token0 = pair.token0 > pair.token1 ? pair.token1 : pair.token0;
        address token1 = pair.token0 < pair.token1 ? pair.token1 : pair.token0;

        (amount_in, due_fee) = _loaner.loan(
            FlashLoaner.FlashParams(
                // e.g.: DAI
                token0,
                // e.g.: USDC
                token1,
                // fee, e.g.: 0.1 %
                _amount_calculator.calculateFee(pair),
                // amount of token0 tokens to loan
                _amount_calculator.calculateAmount(pair),
                // amount of token1 tokens to loan
                0
            )
        );

        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey(
            params.token0,
            params.token1,
            params.fee1
        );

        IUniswapV3Pool pool = IUniswapV3Pool(
            PoolAddress.computeAddress(factory, poolKey)
        );

        pool.flash(
            address(this), // FlashLoaner's callback needs to be triggered, not the bot
            params.amount0,
            params.amount1,
            abi.encode(
                FlashCallbackData({
                    pair: pair,
                    amount0: params.amount0,
                    amount1: params.amount1,
                    payer: msg.sender,
                    poolKey: poolKey,
                    poolFee2: params.fee2,
                    poolFee3: params.fee3
                })
            )
        );

        require(1 == 2); // trigger a revert
    }

    function internalFlashCallback(Libs.FlashCallbackData memory cbdata)
        internal
    {
        string memory best_buy_dex;
        string memory best_sell_dex;
        int256 profit_token0;
        (best_buy_dex, best_sell_dex, profit_token0) = _dex_analyzer
            .analyzeDexes(cbdata);
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        Libs.FlashCallbackData memory decoded = abi.decode(
            data,
            (Libs.FlashCallbackData)
        );
        CallbackValidation.verifyCallback(factory, decoded.poolKey);

        ///============================================
        internalFlashCallback(decoded.pair); // swap with loaned tokens
        ///============================================

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
