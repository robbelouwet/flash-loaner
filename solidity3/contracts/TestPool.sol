// // SPDX-License-Identifier: BUSL-1.1
// pragma solidity =0.7.6;

// import "./libs/@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

// import "./libs/NoDelegateCall.sol";

// import "./libs/@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/SafeCast.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/Tick.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/TickBitmap.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/Position.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/Oracle.sol";

// import "./libs/@uniswap/v3-core/contracts/libraries/FullMath.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/FixedPoint128.sol";
// import "./libs/@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/TickMath.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/LiquidityMath.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/SqrtPriceMath.sol";
// import "./libs/@uniswap/v3-core/contracts/libraries/SwapMath.sol";

// import "./libs/@uniswap/v3-core/contracts/interfaces/IUniswapV3PoolDeployer.sol";
// import "./libs/@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import "./libs/@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
// import "./libs/@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
// import "./libs/@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
// import "./libs/@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";

// contract TestPool is NoDelegateCall {
//     /// @notice Emitted by the pool for any flashes of token0/token1
//     /// @param sender The address that initiated the swap call, and that received the callback
//     /// @param recipient The address that received the tokens from flash
//     /// @param amount0 The amount of token0 that was flashed
//     /// @param amount1 The amount of token1 that was flashed
//     /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
//     /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
//     event Flash(
//         address indexed sender,
//         address indexed recipient,
//         uint256 amount0,
//         uint256 amount1,
//         uint256 paid0,
//         uint256 paid1
//     );

//     using LowGasSafeMath for uint256;
//     using LowGasSafeMath for int256;
//     using SafeCast for uint256;
//     using SafeCast for int256;
//     using Tick for mapping(int24 => Tick.Info);
//     using TickBitmap for mapping(int16 => uint256);
//     using Position for mapping(bytes32 => Position.Info);
//     using Position for Position.Info;
//     using Oracle for Oracle.Observation[65535];

//     ///  IUniswapV3PoolImmutables
//     address public factory;
//     ///  IUniswapV3PoolImmutables
//     address public token0;
//     ///  IUniswapV3PoolImmutables
//     address public token1;
//     ///  IUniswapV3PoolImmutables
//     uint24 public fee;

//     ///  IUniswapV3PoolImmutables
//     int24 public tickSpacing;

//     ///  IUniswapV3PoolImmutables
//     uint128 public maxLiquidityPerTick;

//     struct Slot0 {
//         // the current price
//         uint160 sqrtPriceX96;
//         // the current tick
//         int24 tick;
//         // the most-recently updated index of the observations array
//         uint16 observationIndex;
//         // the current maximum number of observations that are being stored
//         uint16 observationCardinality;
//         // the next maximum number of observations to store, triggered in observations.write
//         uint16 observationCardinalityNext;
//         // the current protocol fee as a percentage of the swap fee taken on withdrawal
//         // represented as an integer denominator (1/x)%
//         uint8 feeProtocol;
//         // whether the pool is locked
//         bool unlocked;
//     }
//     ///  IUniswapV3PoolState
//     Slot0 public slot0;

//     ///  IUniswapV3PoolState
//     uint256 public feeGrowthGlobal0X128;
//     ///  IUniswapV3PoolState
//     uint256 public feeGrowthGlobal1X128;

//     // accumulated protocol fees in token0/token1 units
//     struct ProtocolFees {
//         uint128 token0;
//         uint128 token1;
//     }
//     ///  IUniswapV3PoolState
//     ProtocolFees public protocolFees;

//     ///  IUniswapV3PoolState
//     uint128 public liquidity;

//     ///  IUniswapV3PoolState
//     mapping(int24 => Tick.Info) public ticks;
//     ///  IUniswapV3PoolState
//     mapping(int16 => uint256) public tickBitmap;
//     ///  IUniswapV3PoolState
//     mapping(bytes32 => Position.Info) public positions;
//     ///  IUniswapV3PoolState
//     Oracle.Observation[65535] public observations;

//     /// @dev Mutually exclusive reentrancy protection into the pool to/from a method. This method also prevents entrance
//     /// to a function before the pool is initialized. The reentrancy guard is required throughout the contract because
//     /// we use balance checks to determine the payment status of interactions such as mint, swap and flash.
//     modifier lock() {
//         require(slot0.unlocked, "LOK");
//         slot0.unlocked = false;
//         _;
//         slot0.unlocked = true;
//     }

//     /// @dev Prevents calling a function from anyone except the address returned by IUniswapV3Factory#owner()
//     modifier onlyFactoryOwner() {
//         require(msg.sender == IUniswapV3Factory(factory).owner());
//         _;
//     }

//     constructor() {
//         // DIFF
//         slot0.unlocked = true;

//         /*int24 _tickSpacing;
//         (factory, token0, token1, fee, _tickSpacing) = IUniswapV3PoolDeployer(
//             msg.sender
//         ).parameters();
//         tickSpacing = _tickSpacing;

//         maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(
//             _tickSpacing
//         );*/
//     }

//     ///  IUniswapV3PoolActions
//     function flash(
//         address recipient,
//         uint256 amount0,
//         uint256 amount1,
//         bytes calldata data
//     ) external lock noDelegateCall {
//         uint128 _liquidity = liquidity;
//         //require(_liquidity > 0, "L"); // DIFF

//         uint256 fee0 = FullMath.mulDivRoundingUp(amount0, fee, 1e6);
//         uint256 fee1 = FullMath.mulDivRoundingUp(amount1, fee, 1e6);
//         uint256 balance0Before = balance0();
//         uint256 balance1Before = balance1();

//         if (amount0 > 0)
//             TransferHelper.safeTransfer(token0, recipient, amount0);
//         if (amount1 > 0)
//             TransferHelper.safeTransfer(token1, recipient, amount1);

//         IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(
//             fee0,
//             fee1,
//             data
//         );

//         uint256 balance0After = balance0();
//         uint256 balance1After = balance1();

//         require(balance0Before.add(fee0) <= balance0After, "F0");
//         require(balance1Before.add(fee1) <= balance1After, "F1");

//         // sub is safe because we know balanceAfter is gt balanceBefore by at least fee
//         /*uint256 paid0 = balance0After - balance0Before;
//         uint256 paid1 = balance1After - balance1Before;

//         if (paid0 > 0) {
//             uint8 feeProtocol0 = slot0.feeProtocol % 16;
//             uint256 fees0 = feeProtocol0 == 0 ? 0 : paid0 / feeProtocol0;
//             if (uint128(fees0) > 0) protocolFees.token0 += uint128(fees0);
//             feeGrowthGlobal0X128 += FullMath.mulDiv(
//                 paid0 - fees0,
//                 FixedPoint128.Q128,
//                 _liquidity
//             );
//         }
//         if (paid1 > 0) {
//             uint8 feeProtocol1 = slot0.feeProtocol >> 4;
//             uint256 fees1 = feeProtocol1 == 0 ? 0 : paid1 / feeProtocol1;
//             if (uint128(fees1) > 0) protocolFees.token1 += uint128(fees1);
//             feeGrowthGlobal1X128 += FullMath.mulDiv(
//                 paid1 - fees1,
//                 FixedPoint128.Q128,
//                 _liquidity
//             );
//         }

//         emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);*/
//     }

//     /// @dev Get the pool's balance of token0
//     /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
//     /// check
//     function balance0() private view returns (uint256) {
//         /*(bool success, bytes memory data) = token0.staticcall(
//             abi.encodeWithSelector(
//                 IERC20Minimal.balanceOf.selector,
//                 address(this)
//             )
//         );
//         require(success && data.length >= 32);
//         return abi.decode(data, (uint256));*/
//         return 1000 * (10**18);
//     }

//     /// @dev Get the pool's balance of token1
//     /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
//     /// check
//     function balance1() private view returns (uint256) {
//         /*(bool success, bytes memory data) = token1.staticcall(
//             abi.encodeWithSelector(
//                 IERC20Minimal.balanceOf.selector,
//                 address(this)
//             )
//         );
//         require(success && data.length >= 32);
//         return abi.decode(data, (uint256));*/

//         return 2000 * (10**18);
//     }
// }
