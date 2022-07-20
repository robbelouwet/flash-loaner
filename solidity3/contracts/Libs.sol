// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;
pragma abicoder v2;

import "../libs/v3-periphery/contracts/libraries/PoolAddress.sol";
import "../libs/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "../libs/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

library Libs {
    ISwapRouter constant _uv3_router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IUniswapV2Router02 constant _uv2_router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 constant _sushiswap_router =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    function getUniswapV3Router() internal view returns (ISwapRouter) {
        return _uv3_router;
    }

    function getUniswapV2Router() internal view returns (IUniswapV2Router02) {
        return _uv2_router;
    }

    function getSushiswapRouter() internal view returns (IUniswapV2Router02) {
        return _sushiswap_router;
    }

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

    function rethrowRaw() public view {
        bytes memory _error;
        assembly {
            returndatacopy(_error, 0, returndatasize())
            revert(_error, returndatasize())
        }
        //console.log("Error encountered:");
        //console.logBytes(_error);
    }

    function rethrowError(string memory reason) public pure {
        revert(reason);
    }

    function parseRawError(bytes memory error_stack)
        internal
        view
        returns (uint256)
    {
        console.log("Generic catch{} invoked, bytes:");
        console.logBytes(error_stack);
        if (matchError("TradeResult(uint256)", error_stack))
            return abi.decode(stripSelector(error_stack), (uint256));
        rethrowRaw();
    }

    function handlePanic(uint256 code) internal view {
        console.log("Panic: %d", code);
    }

    function parseReasonedError(string memory _error)
        internal
        view
        returns (uint256 am)
    {
        // error code: L means there's not enough liquidity to loan/swap
        console.log("Caught a revert with reason: %s", _error);
        if (Libs.strEqual(_error, "L")) am = 0;
    }

    function matchError(string memory str, bytes memory b2)
        public
        view
        returns (bool)
    {
        //console.log("Libs::matchError, bytes:");
        //console.logBytes(b2);

        bytes memory strBytes = abi.encodePacked(keccak256(bytes(str)));

        bytes memory b1_cropped = substring(strBytes, 0, 4);
        bytes memory b2_cropped = substring(b2, 0, 4);

        return keccak256(b1_cropped) == keccak256(b2_cropped);
    }

    function substring(
        bytes memory strBytes,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (bytes memory) {
        if (!(startIndex < endIndex)) {
            console.log("startIndex: %d", startIndex);
            console.log("endIndex: %d", endIndex);
            revert("Libs::substring, startIndex >= than endIndex!");
        }
        bytes memory result = new bytes(endIndex - startIndex);

        for (uint256 i = startIndex; i < endIndex; i++)
            result[i - startIndex] = strBytes[i];

        return result;
    }

    function stripSelector(bytes memory b)
        public
        view
        returns (bytes memory res)
    {
        if (b.length <= 4) {
            console.log("exception stack:");
            console.logBytes(b);
            require(b.length > 4, "Faulty exception stack length!");
        }
        res = substring(b, 4, b.length);
    }
}
