// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../Libs.sol";

interface ILoanCalculator {
    /// returns the amount_in to trade, in wei!
    function calculateLoan(Libs.Pair memory pair)
        external
        view
        returns (uint256 amount);
}

contract TestAmountCalculator is ILoanCalculator {
    constructor() ILoanCalculator() {}

    /// returns 1000 tokens
    /// @inheritdoc ILoanCalculator
    function calculateLoan(Libs.Pair memory pair)
        public
        view
        override
        returns (uint256 amount)
    {
        return 1000;
    }
}

contract NaiveAmountCalculator is ILoanCalculator {
    constructor() ILoanCalculator() {}

    /// TODO
    /// 10 percent of the smallest reserve
    /// @inheritdoc ILoanCalculator
    function calculateLoan(Libs.Pair memory pair)
        public
        view
        override
        returns (uint256 amount)
    {}
}

contract EstimatedAmountCalculator is ILoanCalculator {
    constructor() ILoanCalculator() {}

    /// guesstimate a justifiable w.r.t. the fees and gas cost
    ///
    /// Perhaps the most important function
    /// how do we determine the best amount to swap, in order to minimize slippage while still getting profit?
    /// gains if swap arbitrage  >   gas + fee_trade0 + slippage0  + fee_trade1   + slippage1  + flashloan_fee?
    ///          token0          >   eth +   token0   +   token0   +    token1    +    token1  +    token0
    /// if gains is positive, we have a winner
    /// @inheritdoc ILoanCalculator
    function calculateLoan(Libs.Pair memory pair)
        public
        view
        override
        returns (uint256 amount)
    {}
}
