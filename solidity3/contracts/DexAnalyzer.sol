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
}
