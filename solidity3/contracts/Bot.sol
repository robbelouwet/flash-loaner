// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import {FlashLoaner} from "./FlashLoaner.sol";
import {DexAnalyzer} from "./DexAnalyzer.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v3-periphery/contracts/interfaces/IQuoter.sol";

contract Bot {
    // contract owner
    address _owner;
    FlashLoaner _loaner;
    DexAnalyzer _dex_analyzer;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    //=========================================================================
    // - deploy en doe test run
    // - debug: kan em al amount_out terug geven en vinden?
    constructor(address payable flash_loaner, address dex_analyzer) {
        _loaner = FlashLoaner(flash_loaner);
        _dex_analyzer = DexAnalyzer(dex_analyzer);

        _owner = msg.sender;
    }

    //=========================================================================

    function findArbitrage()
        public
        returns (
            address token_in_loan,
            address token_out,
            address dex_buy,
            address dex_sell
        )
    {
        /*
        address token0;
        address token1;
        uint24 fee1;
        uint256 amount0;
        uint256 amount1;
        uint24 fee2;
        uint24 fee3;
        uint256 amount_in;
        uint256 due_fee;
        (amount_in, due_fee) = _loaner.loan(
            FlashLoaner.FlashParams(
                0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
                100, // ropsten: 3000, mainnet: 100
                10 * (10**18), // 10 USDC,
                0,
                0,
                0
            )
        );

        // find the best buy and sell dexes for the specified pair
        for (uint256 i = 0; i < _pools.length; i++) {
            address best_buy_dex;
            address best_sell_dex;

            (best_buy_dex, best_sell_dex) = analyzeDexes(
                amount_in,
                _pools[i][0],
                _pools[i][1]
            );
        }*/

        token_in_loan = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        token_out = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        dex_buy = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        dex_sell = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    }
}
