// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/v3-periphery/contracts/libraries/PoolAddress.sol";
import "hardhat/console.sol";

library Libs {
    struct Pair {
        address token0;
        address token1;
        address uniswap_v3_100;
        address uniswap_v3_500;
        address uniswap_v3_1000;
        address uniswap_v3_3000;
        address uniswap_v3_10000;
        address uniswap_v2;
        address sushiswap;
    }

    struct Trade {
        int256 profit;
        Pair pair;
        string dex_swap_in;
        string dex_swap_out;
    }

    struct FlashParams {
        address token0;
        address token1;
        uint24 fee1;
        uint256 amount0;
        uint256 amount1;
    }

    struct FlashCallbackData {
        Pair pair;
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey;
        bool _revert;
    }

    function strEqual(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encode(str1)) == keccak256((abi.encode(str2))));
    }

    function rethrow() public view {
        // rethrow a caught Error
        bytes memory _error;
        assembly {
            returndatacopy(_error, 0, returndatasize())
            revert(_error, returndatasize())
        }
        console.log("Error encountered:");
        console.logBytes(_error);
    }

    function matchError(string memory str, bytes memory b2)
        public
        view
        returns (bool)
    {
        console.log("Libs::matchError, bytes:");
        console.logBytes(b2);

        bytes memory strBytes = abi.encodePacked(keccak256(bytes(str)));

        bytes memory b1_cropped = substring(strBytes, 0, 4);
        bytes memory b2_cropped = substring(b2, 0, 4);

        return keccak256(b1_cropped) == keccak256(b2_cropped);
    }

    function substring(
        bytes memory strBytes,
        uint256 startIndex,
        uint256 endIndex
    ) public pure returns (bytes memory) {
        bytes memory result = new bytes(endIndex - startIndex);

        for (uint256 i = startIndex; i < endIndex; i++)
            result[i - startIndex] = strBytes[i];

        return result;
    }

    function stripSelector(bytes memory b)
        public
        pure
        returns (bytes memory res)
    {
        res = substring(b, 4, b.length);
    }
}
