// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.30;

/**
 *
 * @title Library to handle liquidity action requests
 *
 * @notice Library containing structs related to liquidity requests such
 * as add liquidity and remove liquidity for all the dexs supported.
 *
 * @author Zup Protocol
 * */
library LiquidityActionRequest {
    /**
     *  @notice parameters that every add or remove liquidity request needs to have
     *  to perform the action, doesn't matter the DEX.
     *
     * @param receiver address of the user receiving the liquidity
     *
     * @param amount0 amount of token0 to add or remove from the pool
     *
     * @param amount1 amount of token1 to add or remove from the pool
     *
     * @param token0 address of pool token0
     *
     * @param token1 address of pool token1
     *
     * @param positionManager address of the position manager contract
     * for the DEX where liquidity will be added or removed
     *
     */ // solhint-disable gas-struct-packing
    struct LiquidityActionParams {
        address receiver;
        uint128 amount0;
        uint128 amount1;
        address token0;
        address token1;
        address positionManager;
    }

    /**
     * @notice parameters needed to add liquidity into Uniswap V3-style pools
     *
     * @dev using uint128 for deadline to optimize struct packing, as it will
     * be packed with the params before
     *  */
    struct UniswapV3AddLiquidityParams {
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 deadline;
        uint128 amount0Min;
        uint128 amount1Min;
    }
}
