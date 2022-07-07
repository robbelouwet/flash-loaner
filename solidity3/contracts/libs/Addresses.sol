// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7;
pragma abicoder v2;

abstract contract Addresses {
    address public uniswap_weth9;
    address public dai;
    address public usdc;

    address public uniswap_router;
}

contract MainAddresses is Addresses {}

contract RopstenAddresses is Addresses {}
