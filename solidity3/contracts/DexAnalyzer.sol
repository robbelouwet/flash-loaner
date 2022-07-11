// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/Strings.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libs/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {Libs} from "../libs/PairLibs.sol";

contract DexAnalyzer {
    using strings for *;

    address _owner;

    // name of the dexes: uniswap_v3, uniswap_v2, sushiswap
    string[] _dex_ids;

    // routers
    mapping(string => address) public _routers;

    address _uniswap_v3_quoter;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;

        _dex_ids.push("uniswap_v3");
        _dex_ids.push("sushiswap");
        _dex_ids.push("uniswap_v2");

        _routers["uniswap_v3"] = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        _routers["uniswap_v2"] = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        _routers["sushiswap"] = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

        _uniswap_v3_quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    }

    function analyzeDexes(uint256 amount_in, Libs.Pair memory pair)
        public
        returns (string memory best_buy_dex, string memory best_sell_dex)
    {
        // keep track of the best arb opportunity
        // while analyzing dexes
        uint256 highest_amount_out = 0;
        uint256 lowest_amount_out = 2**255; // some amount close to 'inf'

        for (uint256 i = 0; i < _dex_ids.length; i++) {
            // the juicy boi (not gas efficient):
            uint256 am = getAmountOut(amount_in, pair);
            // is this a good buy DEX? Give little t_in, receive alot t_out?
            if (am > highest_amount_out) {
                highest_amount_out = am;
                best_buy_dex = _dex_ids[i];
            }

            // is this a good sell DEX? Sell little t_out, get alot of t_in
            if (am < lowest_amount_out) {
                lowest_amount_out = am;
                best_sell_dex = _dex_ids[i];
            }
        }
    }

    function getAmountOut(uint256 amount_in, Libs.Pair memory pair)
        public
        returns (uint256)
    {
        // uniswap V3, 0.01% fee
        if (pair.uniswap_v3_100 != address(0x0)) checkUniswapV3AmountOut(100);

        // uniswap V3, 0.5% fee
        if (pair.uniswap_v3_500 != address(0x0)) checkUniswapV3AmountOut(500);

        // uniswap V3, 0.3% fee
        if (pair.uniswap_v3_3000 != address(0x0)) checkUniswapV3AmountOut(3000);

        // uniswap V3, 1% fee
        if (pair.uniswap_v3_10000 != address(0x0))
            checkUniswapV3AmountOut(10000);

        // uniswap V2
        if (pair.uniswap_v2 != address(0x0)) checkUniswapV2AmountOut();

        // sushiswap
        if (pair.uniswap_v3_100 != address(0x0)) checkUniswapV2AmountOut();
    }

    function checkUniswapV3AmountOut(uint256 fee)
        public
        view
        returns (uint256)
    {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(

        );
        try ISwapRouter(_routers["uniswap_v3"]).exactInputSingle(params)
            returns (uint amount_out) {
            
        } catch Error(string memory reason) {

        };
    }

    function checkUniswapV2AmountOut() public view returns (uint256) {}
}
