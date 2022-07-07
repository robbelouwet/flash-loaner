// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7;
pragma abicoder v2;

import {FlashLoaner} from "./FlashLoaner.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

contract Bot {
    // contract owner
    address _owner;
    FlashLoaner _loaner;

    // routers
    string[] _routers_ids;
    mapping(string => address) public _routers;

    // quoters
    string[] _quoters_ids;
    mapping(string => address) public _quoters;

    // array of (token0, token1) token pairs present on at least 2 of our DEX's
    address[][2] _pools;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    //=========================================================================
    // - deploy en doe test run
    // - debug: kan em al amount_out terug geven en vinden?
    constructor(address payable flash_loaner) {
        _loaner = FlashLoaner(flash_loaner);
        _owner = msg.sender;

        _routers_ids.push("uniswap");
        _routers["uniswap"] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        _quoters_ids.push("uniswap");
        _quoters["uniswap"] = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
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
        */
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
        /*for (uint256 i = 0; i < _pools.length; i++) {
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

    function analyzeDexes(
        uint256 amount_in,
        address token_in,
        address token_out
    ) public returns (address best_buy_dex, address best_sell_dex) {
        // keep track of the best arb opportunity
        // while analyzing dexes
        uint256 highest_amount_out = 0;
        uint256 lowest_amount_out = 2**255; // some amount close to 'inf'

        for (uint256 i = 0; i < _quoters_ids.length; i++) {
            // the juicy boi (not gas efficient):
            uint256 am = IQuoter(_quoters[_quoters_ids[i]])
                .quoteExactInputSingle(
                    token_in,
                    token_out,
                    100, // fee, 0.1 %
                    amount_in,
                    0
                );
            // is this a good buy DEX? Give little t_in, receive alot t_out?
            if (am > highest_amount_out) {
                highest_amount_out = am;
                best_buy_dex = _routers[_routers_ids[i]];
            }

            // is this a good sell DEX? Sell little t_out, get alot of t_in
            if (am < lowest_amount_out) {
                lowest_amount_out = am;
                best_sell_dex = _routers[_routers_ids[i]];
            }
        }
    }
}
