// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {LiquidityActionRequest} from "../libraries/LiquidityActionRequest.sol";

/**
 * @title IPoolModule
 * @author Zup Protocol
 * @notice Interface for base pool modules handling actions for different DEXs.
 *
 * This interface defines the standardized entry point for managing pool liquidity
 * across various decentralized exchanges (DEXs).
 */
interface IPoolModule {
    /**
     * @notice Emitted when a user successfully adds liquidity to a pool managed by this module.
     *
     * This event provides transparency for off-chain tools, analytics, and other contracts
     * to track liquidity additions across different DEX integrations.
     *
     * @param receiver The address of the account receiving the liquidity.
     *
     * @param token0 The address of the first token in the liquidity pair.
     *
     * @param token1 The address of the second token in the liquidity pair.
     *
     * @param sender The address of the user who sent the tokens to add liquidity.
     *
     * @param amount0 The amount of `token0` added to the pool.
     *
     * @param amount1 The amount of `token1` added to the pool.
     */
    event LiquidityAdded(
        address indexed receiver,
        address indexed token0,
        address indexed token1,
        address sender,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Error raised when a call is made to the module with unsupported calldata.
     *
     * This error is triggered when the provided calldata does not match any
     * recognized function selector and falls into the module’s fallback function.
     */
    error UnsupportedModuleCall();

    /**
     * @notice Adds liquidity to the controlled pool for a specific DEX.
     *
     * @param actionData Struct containing the common parameters required
     * for adding liquidity to the pool, defined in `LiquidityActionRequest`.
     *
     * @param moduleData ABI-encoded parameters to be passed to the DEX-specific
     * `addLiquidity` function in the DEX module, this is specific to each DEX,
     * but should be found at `LiquidityActionRequest` library for each DEX.
     *
     * @dev Implementing contracts should not override this function directly. Instead,
     * override `_executeAddLiquidity` to provide the DEX-specific logic. This function
     * ensures consistent token handling, refunds, and event emission across all
     * pool modules.
     */
    function addLiquidity(LiquidityActionRequest.LiquidityActionParams calldata actionData, bytes calldata moduleData) external payable;

    /**
     * @notice Returns a unique identifier key for the pool module.
     *
     * @return bytes4 The unique key representing this module.
     *
     * @dev This key allows other contracts to reference and manage different pool modules
     * in a standardized manner. Every module implementation must define and expose its own
     * unique key, ensuring consistent identification across the protocol.
     *
     * The key should be unique across all deployed modules to prevent conflicts when
     * managing multiple integrations within the same system. For maintainability and
     * traceability, it is recommended that the key remains constant for the same module
     * across all versions.
     *
     * For better integration across Zup Protocol ecosystem, it is recommended to use the
     * same key as the indexer for the protocol hashed as bytes4, e.g. `bytes4(keccak256("uniswap-v3"))`.
     *
     * See [Indexer Protocols](https://github.com/Zup-Protocol/pools-indexer/blob/main/src/common/enums/supported-protocol.ts#L8-L30)
     */
    function key() external pure returns (bytes4);

    /**
     * @notice Returns the version identifier of this pool module.
     * @dev Used by off-chain tools and integrations to identify the module implementation version.
     * @return version The version string of the module, e.g. "1.0.0".
     */
    function version() external pure returns (string memory version);
}
