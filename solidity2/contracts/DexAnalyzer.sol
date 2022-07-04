// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import {ISwapRouter} from "https://raw.githubusercontent.com/Uniswap/v3-periphery/main/contracts/interfaces/ISwapRouter.sol";

contract DexAnalyzer {
    address _owner;

    string[] _dex_ids;
    mapping(string => address) _routers;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address owner) {
        _owner = owner;
        _routers["uniswap"] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    }

    function analyzeDexes(
        uint256 amount_in,
        address token_in,
        address token_out
    ) public view returns (address best_dex_in, address best_dex_out) {
        // keep track of the best arb opportunity
        // while analyzing dexes
        uint256 highest_amount_out = 0;
        uint256 lowest_amount_out = 2**254; // some amount close to 'inf'

        for (uint256 i = 0; i < _dex_ids.length; i++) {
            ISwapRouter router = ISwapRouter(_routers[_dex_ids[i]]);
            ISwapRouter.ExactInputSingleParams params = ISwapRouter
                .ExactInputSingleParams(); //TODO

            uint256 am = router.exactInputSingle(params);

            if (am > highest_amount_out) {
                highest_amount_out = am;
                best_dex_in = _dex_ids[i];
            }

            if (am < lowest_amount_out) {
                lowest_amount_out = am;
                best_dex_out = _dex_ids[i];
            }
        }
    }
}
