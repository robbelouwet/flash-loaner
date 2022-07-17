// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../Libs.sol";

interface IFeeCalculator {
    function calculateFee(Libs.Pair memory pair)
        external
        view
        returns (uint256 amount);
}

contract TestFeeCalculator is IFeeCalculator {
    constructor() IFeeCalculator() {}

    /// returns 1000 tokens
    /// @inheritdoc IFeeCalculator
    function calculateFee(Libs.Pair memory pair)
        public
        view
        override
        returns (uint256 amount)
    {
        /// just return 1000 tokens
        return 100;
    }
}

contract NaiveFeeCalculator is IFeeCalculator {
    constructor() IFeeCalculator() {}

    /// returns 1000 tokens
    /// @inheritdoc IFeeCalculator
    function calculateFee(Libs.Pair memory pair)
        public
        view
        override
        returns (uint256 amount)
    {
        /// just return 1000 tokens
        return 100;
    }
}

contract EstimatedFeeCalculator is IFeeCalculator {
    constructor() IFeeCalculator() {}

    /// returns 1000 tokens
    /// @inheritdoc IFeeCalculator
    function calculateFee(Libs.Pair memory pair)
        public
        view
        override
        returns (uint256 amount)
    {
        /// just return 1000 tokens
        return 100;
    }
}
