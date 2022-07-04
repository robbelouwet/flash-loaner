// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

contract DexAnalyzer {
    address _owner;

    // routers
    string[] _routers_ids;
    mapping(string => address) public _routers;

    // quoters
    string[] _quoters_ids;
    mapping(string => address) public _quoters;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;

        _routers_ids.push("uniswap");
        _routers["uniswap"] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        _quoters_ids.push("uniswap");
        _quoters["uniswap"] = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
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
