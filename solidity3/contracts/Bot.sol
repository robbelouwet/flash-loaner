// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import {FlashLoaner} from "./FlashLoaner.sol";
import {DexAnalyzer} from "./DexAnalyzer.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./Structs.sol";
import "./IAmountCalculator.sol";
import "hardhat/console.sol";

contract Bot {
    // contract owner
    address _owner;
    FlashLoaner _loaner;
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
    constructor(address payable flash_loaner) {
        // let's start with amount_in = 1000 tokens
        _amount_calculator = new TestAmountCalculator();

        _loaner = FlashLoaner(flash_loaner);
        _dex_analyzer = DexAnalyzer(dex_analyzer);

        _owner = msg.sender;
    }

    //=========================================================================

    function start() public {
        Trade[] profitable_trades;

        for (uint256 i = 0; i < _common_pairs.length; i++) {
            // either there's profit, which means the trade is executed
            // or there was loss, which mean it was reverted
            // in both cases, the result is saved in _loaner.results
            (dex_in, dex_out, profit) = _loaner.analyzePair(
                _common_pairs[i],
                __revert = true
            );
        }

        performProfitableTrades(profitable_trades);
    }

    function saveCommonPairs(Libs.Pair[] memory pairs) public {
        for (uint256 i = 0; i < pairs.length; i++) {
            _common_pairs.push(pairs[i]);
        }
    }

    function getCommonPairsLength() public view returns (uint256) {
        return _common_pairs.length;
    }
}
