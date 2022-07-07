// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7;
pragma abicoder v2;

contract AaveFlashLoaner {
    address _owner;
    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }
}
