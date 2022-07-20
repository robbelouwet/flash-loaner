// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "../libs/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../libs/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "../libs/v3-core/contracts/interfaces/IERC20Minimal.sol";

import "../libs/v3-periphery/contracts/base/PeripheryPayments.sol";
import "../libs/v3-periphery/contracts/base/PeripheryImmutableState.sol";
import "../libs/v3-periphery/contracts/libraries/PoolAddress.sol";
import "../libs/CallbackValidation.sol";
import "../libs/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./DexAnalyzer.sol";
import "./Libs.sol";
import "./strategies/ILoanCalculator.sol";
import "../libs/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "../libs/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract FlashLoaner is IUniswapV3FlashCallback, PeripheryPayments {
    address _owner;

    DexAnalyzer _dex_analyzer;
    ILoanCalculator _loan_calulator;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;

    // uniswap V3 router
    ISwapRouter _flashloan_swap_router;

    constructor(
        ISwapRouter _swapRouter,
        address dex_analyzer,
        address _factory,
        address _WETH9
    ) PeripheryImmutableState(_factory, _WETH9) {
        _dex_analyzer = DexAnalyzer(dex_analyzer);
        _flashloan_swap_router = ISwapRouter(_swapRouter);
        _owner = msg.sender;
        _loan_calulator = new TestAmountCalculator();
    }

    /// Analyze a given pair of ERC20 tokens, and see if there's an arbitrage opportunity
    /// among our known DEX's.
    ///
    /// performs a swap. If specified, fails on purpose in order to revert and see if the trade would have been profitable
    function flashAnalyzePair(
        Libs.Pair memory pair,
        address token0,
        address token1,
        uint24 loan_fee
    ) public {
        console.log("FlashLoaner::flashAnalyzePair1");
        // console.log(
        //     "token0: %s,\ntoken1: %s, fee: %d",
        //     token0,
        //     token1,
        //     loan_fee
        // );
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey({
            token0: token0,
            token1: token1,
            fee: loan_fee
        });

        console.log("FlashLoaner::flashAnalyzePair2");

        IUniswapV3Pool pool = IUniswapV3Pool(
            PoolAddress.computeAddress(factory, poolKey)
        );
        // console.log("pool address: %s", address(pool));

        console.log("FlashLoaner::flashAnalyzePair3");

        uint256 loan = _loan_calulator.calculateLoan(pair);
        console.log("FlashLoaner::flashAnalyzePair4");

        Libs.FlashCallbackData memory cbdata = Libs.FlashCallbackData({
            pair: pair,
            amount0: loan,
            amount1: 0,
            payer: msg.sender,
            poolKey: poolKey,
            _revert: true
        });

        // try

        ensureLiquidity(token0, token1, loan_fee);
        pool.flash(
            address(this), // FlashLoaner's callback needs to be triggered, not the bot
            loan,
            0,
            abi.encode(cbdata)
        );
        // {} catch Error(string memory str) {
        //     Libs.parseReasonedError(str);
        // } catch Panic(uint256 reason) {
        //     Libs.handlePanic(reason);
        // }
        // catch (bytes memory b) {
        //     string memory iets = abi.decode(Libs.stripSelector(b), (string));
        //     if (!Libs.matchError("ArbitrageResult(int256,string,string)", b))
        //         Libs.rethrowRaw();
        // bytes32 iets2 = keccak256(
        //     bytes("ArbitrageResult(int256,bytes,bytes)")
        // );
        // console.log("FlashLoan error, bytes:\n");
        // console.logBytes(b);
        // console.log("selector hash:\n");
        // console.logBytes32(iets2);
        // Libs.rethrowRaw();
        // }
    }

    function ensureLiquidity(
        address token0,
        address token1,
        uint24 loan_fee
    ) {
        // probeer die 'L' error message te voorkomen zodat alleen de gewilde error voorkomt
        // dan overal de try catch weghalen zoda we een volledige stacktrace zien van de gewilde errmsg
        IUniswapV3Factory f = IUniswapV3Factory(
            Libs.getUniswapV3Router().factory() // doe static call zoals uniswap soms doet
        );
        IUniswapV3Pool pool = f.getPool(token0, token1, loan_fee);
        require(pool.liquidity() > 0, "Pool has no liquidity");
    }

    function internalFlashCallback(Libs.FlashCallbackData memory cbdata)
        internal
        returns (
            string memory best_buy_dex,
            string memory best_sell_dex,
            uint256 amount_out_token0
        )
    {
        console.log("Entered internalCallback");
        (best_buy_dex, best_sell_dex, amount_out_token0) = _dex_analyzer
            .analyzeDexes(cbdata);
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        console.log("Entered UniswapV3Callback");
        Libs.FlashCallbackData memory decoded = abi.decode(
            data,
            (Libs.FlashCallbackData)
        );

        console.log(
            "balance of token (%s):\n%d",
            decoded.pair.token0,
            IERC20Minimal(decoded.pair.token0).balanceOf(address(this))
        );
        CallbackValidation.verifyCallback(factory, decoded.poolKey);

        ///============================================
        // now that we have the flash loan, execute the arbitrage
        string memory best_buy_dex;
        string memory best_sell_dex;
        uint256 amountOut0;
        (best_buy_dex, best_sell_dex, amountOut0) = internalFlashCallback(
            decoded
        );
        ///============================================

        address token0 = decoded.poolKey.token0;
        address token1 = decoded.poolKey.token1;

        TransferHelper.safeApprove(
            token0,
            address(_flashloan_swap_router),
            decoded.amount0
        );
        // TransferHelper.safeApprove(
        //     token1,
        //     address(_flashloan_swap_router),
        //     decoded.amount1
        // );

        // profitable check
        // exactInputSingle will fail if this amount not met
        uint256 amount0Min = LowGasSafeMath.add(decoded.amount0, fee0);
        //uint256 amount1Min = LowGasSafeMath.add(decoded.amount1, fee1);

        // call exactInputSingle for swapping token1 for token0 in pool w/fee2
        // uint256 amountOut0 = _flashloan_swap_router.exactInputSingle(
        //     ISwapRouter.ExactInputSingleParams({
        //         tokenIn: token1,
        //         tokenOut: token0,
        //         fee: decoded.poolFee2,
        //         recipient: address(this),
        //         deadline: block.timestamp + 200,
        //         amountIn: decoded.amount1,
        //         amountOutMinimum: amount0Min,
        //         sqrtPriceLimitX96: 0
        //     })
        // );

        // call exactInputSingle for swapping token0 for token 1 in pool w/fee3
        // uint256 amountOut1 = _flashloan_swap_router.exactInputSingle(
        //     ISwapRouter.ExactInputSingleParams({
        //         tokenIn: token0,
        //         tokenOut: token1,
        //         fee: decoded.poolFee3,
        //         recipient: address(this),
        //         deadline: block.timestamp + 200,
        //         amountIn: decoded.amount0,
        //         amountOutMinimum: amount1Min,
        //         sqrtPriceLimitX96: 0
        //     })
        // );

        // end up with amountOut0 of token0 from first swap and amountOut1 of token1 from second swap
        uint256 amount0Owed = LowGasSafeMath.add(decoded.amount0, fee0);
        // uint256 amount1Owed = LowGasSafeMath.add(decoded.amount1, fee1);

        TransferHelper.safeApprove(token0, address(this), amount0Owed);
        // TransferHelper.safeApprove(token1, address(this), amount1Owed);

        if (amount0Owed > 0)
            pay(token0, address(this), msg.sender, amount0Owed);
        // if (amount1Owed > 0)
        //     pay(token1, address(this), msg.sender, amount1Owed);

        // if profitable pay profits to payer
        if (amountOut0 > amount0Owed) {
            uint256 profit0 = LowGasSafeMath.sub(amountOut0, amount0Owed);

            TransferHelper.safeApprove(token0, address(this), profit0);
            pay(token0, address(this), decoded.payer, profit0);
        }
        // if (amountOut1 > amount1Owed) {
        //     uint256 profit1 = LowGasSafeMath.sub(amountOut1, amount1Owed);
        //     TransferHelper.safeApprove(token0, address(this), profit1);
        //     pay(token1, address(this), decoded.payer, profit1);
        // }
    }

    // function runPreemptiveChecks(address token0, address token1) internal view {
    //     // these are require()'s that are executed on uniswap's end, but return no error msg
    //     // let's execute them now wíth an err msg
    //     bool success0;
    //     bytes memory data0;
    //     (success0, data0) = token0.staticcall(
    //         abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, msg.sender)
    //     );
    //     require(success0 && data0.length >= 32, "Balance0 error");
    //     bool success1;
    //     bytes memory data1;
    //     (success1, data1) = token1.staticcall(
    //         abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, msg.sender)
    //     );
    //     require(success1 && data1.length >= 32, "Balance1 error");
    // }
}
