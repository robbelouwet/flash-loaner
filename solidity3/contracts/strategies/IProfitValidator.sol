// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../Libs.sol";

interface IProfitValidator {
    function isProfitable(Libs.Trade memory trade) external pure returns (bool);
}

contract NaiveProfitValidator is IProfitValidator {
    constructor() IProfitValidator() {}

    function isProfitable(Libs.Trade memory trade)
        external
        pure
        override
        returns (bool)
    {
        return trade.profit > 0;
    }
}
