// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

import "hardhat/console.sol";

contract Test {
    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    constructor() {
        PoolKey memory key = PoolKey(
            0x6B175474E89094C44Da98b954EedeAC495271d0F,
            0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            100
        );

        address pool = computeAddress(
            0x1F98431c8aD98523631AE4a59f267346ea31F984,
            key
        );

        // returns
        // 0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168
    }

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key)
        internal
        view
        returns (address pool)
    {
        require(key.token0 < key.token1);
        bytes32 _hash = keccak256(
            abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encode(key.token0, key.token1, key.fee)),
                POOL_INIT_CODE_HASH
            )
        );

        assembly {
            pool := _hash
        }
        console.log(pool);
    }
}
