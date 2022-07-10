// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.5;
pragma abicoder v2;

import {FlashLoaner} from "./FlashLoaner.sol";
import {DexAnalyzer} from "./DexAnalyzer.sol";
import "./libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./libs/v3-periphery/contracts/interfaces/IQuoter.sol";

contract Bot {
    // contract owner
    address _owner;
    FlashLoaner _loaner;
    DexAnalyzer _dex_analyzer;

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
    constructor(address payable flash_loaner, address dex_analyzer) {
        _loaner = FlashLoaner(flash_loaner);
        _dex_analyzer = DexAnalyzer(dex_analyzer);

        _owner = msg.sender;

        _routers_ids.push("uniswap_v3");
        _router_ids.push("sushiswap");
        _router_ids.push("uniswap_v2");
        _routers["uniswap_v3"] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        _routers["uniswap_v2"] = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _routers["sushiswap"] = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
        _routers[""] = ;

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
