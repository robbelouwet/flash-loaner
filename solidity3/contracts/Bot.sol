// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import {FlashLoaner} from "./FlashLoaner.sol";
import {DexAnalyzer} from "./DexAnalyzer.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./Libs.sol";
import "./strategies/ILoanCalculator.sol";
import "./strategies/IProfitValidator.sol";
import "hardhat/console.sol";
import "./DexHandler.sol";

contract Bot {
    address _owner;
    FlashLoaner _loaner;
    IProfitValidator _validator;
    Libs.Pair[] _common_pairs;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address payable flash_loaner) {
        _loaner = FlashLoaner(flash_loaner);
        _validator = new NaiveProfitValidator();
        _owner = msg.sender;
    }

    //=========================================================================

    function start() public {
        // first execute trades optimistically and then revert to see which Trades are profitable
        for (uint256 i = 0; i < _common_pairs.length; i++) {
            Libs.Pair memory pair = _common_pairs[i];
            Libs.Trade memory trade;
            address loan_pool_token1;
            uint24 loan_fee;
            console.log("bot::start");
            (loan_pool_token1, loan_fee) = findDifferentPool(pair, pair.token0);

            // test flashAnalyzePair
            // try
            _loaner.flashAnalyzePair(
                pair,
                pair.token0,
                loan_pool_token1,
                loan_fee
            );
            // {
            //     // should never enter
            //     revert("Entered unreachable try block, Bot::start");
            // } catch (bytes memory b) {
            //     // catch the arbitrage error
            //     console.log("Bytes:");
            //     console.logBytes(b);
            //     if (
            //         !Libs.matchError("ArbitrageResult(int256,string,string)", b)
            //     ) Libs.rethrow();
            //     bytes memory stripped = Libs.stripSelector(b);

            //     // decode exception data
            //     string memory dex_in;
            //     string memory dex_out;
            //     int256 profit;
            //     (profit, dex_in, dex_out) = abi.decode(
            //         stripped,
            //         (int256, string, string)
            //     );

            //     // parse it as a trade
            //     trade = Libs.Trade(profit, pair, dex_in, dex_out);

            //     //console.log("Catch executed, amount: %d", profit);
            // }

            // if that trade was profitable, save it
            if (_validator.isProfitable(trade))
                // then perform the profitable trade
                performProfitableTrade(trade);
        }
    }

    function findDifferentPool(Libs.Pair memory pair, address token_to_loan)
        internal
        view
        returns (address token1, uint24 loan_fee)
    {
        console.log("bot::findDifferentPool");
        return (pair.token1, 100);
    }

    function performProfitableTrade(Libs.Trade memory trades) internal {
        // TODO
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
