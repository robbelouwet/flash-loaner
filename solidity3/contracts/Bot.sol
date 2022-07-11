// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import {FlashLoaner} from "./FlashLoaner.sol";
import {DexAnalyzer} from "./DexAnalyzer.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v3-periphery/contracts/interfaces/IQuoter.sol";
import {Libs} from "../libs/PairLibs.sol";
import "./IAmountCalculator.sol";

contract Bot {
    // contract owner
    address _owner;
    FlashLoaner _loaner;
    DexAnalyzer _dex_analyzer;
    IAmountCalculator _amount_calculator;

    // a list of Libs.Pair structs the signify a pair of ERC20 tokens available to swap on which DEX's
    Libs.Pair[] _common_pairs;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    //=========================================================================
    // - deploy en doe test run
    // - debug: kan em al amount_out terug geven en vinden?
    constructor(address payable flash_loaner, address dex_analyzer) {
        // let's start with amount_in = 1000 tokens
        _amount_calculator = new TestAmountCalculator();

        _loaner = FlashLoaner(flash_loaner);
        _dex_analyzer = DexAnalyzer(dex_analyzer);

        _owner = msg.sender;
    }

    //=========================================================================

    function start() public {
        for (uint256 i = 0; i < _common_pairs.length; i++) {
            int256 profit;
            try analyzePair(_common_pairs[i]) returns (uint256 _profit) {
                profit = _profit;
            } catch Error(string memory reason) {
                continue;
            }
        }
    }

    function saveCommonPairs(Libs.Pair[] memory pairs) public {
        for (uint256 i = 0; i < pairs.length; i++) {
            _common_pairs.push(pairs[i]);
        }
    }

    function getCommonPairsLength() public view returns (uint256) {
        return _common_pairs.length;
    }

    /// Analyze a given pair of ERC20 tokens, and see if there's an arbitrage opportunity
    /// among our known DEX's.
    ///
    /// performs a swap and requires() the profit to be positive, otherwise fail
    function analyzePair(Libs.Pair memory pair) public {
        address token0 = pair.token0 > pair.token1 ? pair.token1 : pair.token0;
        address token1 = pair.token0 < pair.token1 ? pair.token1 : pair.token0;

        (amount_in, due_fee) = _loaner.loan(
            FlashLoaner.FlashParams(
                // e.g.: DAI
                token0,
                // e.g.: USDC
                token1,
                // fee, e.g.: 0.1 %
                100,
                // amount of token0 tokens to loan
                _amount_calculator.calculate(pair),
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
            address(_loaner), // FlashLoaner's callback needs to be triggered, not the bot
            params.amount0,
            params.amount1,
            abi.encode(
                FlashCallbackData({
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
}
