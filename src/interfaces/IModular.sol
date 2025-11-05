// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {IPoolModule} from "../interfaces/IPoolModule.sol";

/**
 * @title IModular
 * @author Zup Protocol
 * @notice Interface defining the core modular architecture for pool module interaction.
 *
 * This interface provides a unified entry point for interacting with multiple pool modules,
 * each responsible for a specific DEX integration (e.g., Uniswap, Aerodrome, PancakeSwap).
 * It allows external contracts or users to dynamically select a pool module type and perform
 * supported actions such as adding liquidity, removing liquidity, etc...
 *
 * @custom:version 1.0.0
 */
interface IModular {
    /**
     * @notice Structure representing a pending pool module implementation scheduled for activation.
     * @dev Stores the address of the new module implementation and the timestamp when it was scheduled.
     * Used to enforce a minimum delay before the new module can be activated, providing a security buffer
     * against accidental or malicious upgrades. The delay allows for review and, if necessary, cancellation
     * of the scheduled module update before it is finalized.
     *
     * @param module The address of the pool module implementation that has been scheduled for activation.
     * @param sinceBlockTimestamp The block timestamp at which this module was scheduled, used to calculate
     * the required delay period before activation via `updateModule`.
     */
    struct UpcomingModule {
        address module;
        uint256 sinceBlockTimestamp;
    }

    /**
     * @notice Emitted when a new pool module implementation is registered or updated for a given module type.
     *
     * This event provides transparency for configuration changes in the modular architecture,
     * allowing off-chain services, protocol governors, or other contracts to track which
     * pool module implementation is associated with each key.
     *
     * @param moduleKey The key of the pool module being set or updated.
     *
     * @param module The address of the deployed pool module implementation assigned to the given module key.
     */
    event ModuleSet(bytes4 indexed moduleKey, address indexed module);

    /**
     * @notice Emitted when a new pool module implementation is scheduled to be registered or updated for a given module key.
     *
     * This event provides transparency for configuration changes in the modular architecture,
     * allowing off-chain services, protocol governors, or other contracts to track which
     * pool module implementation is scheduled to be registered or updated for a given module type.
     *
     * @param moduleKey The key of the pool module whose implementation is scheduled to be registered or updated.
     *
     * @param newModule The address of the deployed pool module implementation that is scheduled to be registered or updated.
     *
     * @param blockTimestamp The block timestamp when the module update is scheduled.
     */
    event ModuleScheduled(bytes4 indexed moduleKey, address indexed newModule, uint256 indexed blockTimestamp);

    /**
     * @notice Emitted when a previously scheduled module update is canceled before it becomes active.
     *
     * This event provides transparency for configuration changes in the modular architecture,
     * allowing off-chain services, protocol governors, or other contracts to track cancellations
     * of scheduled module updates for specific module keys.
     *
     * @param moduleKey The key of the pool module whose scheduled update has been canceled.
     */
    event ScheduledModuleCanceled(bytes4 indexed moduleKey, address indexed canceledModule);

    /**
     * @notice Error raised when attempting to update a pool module type that has no scheduled update.
     *
     * This error indicates that there is no pending module implementation registered
     * for the specified `moduleKey` that can be activated via `updateModule`.
     *
     * @param moduleKey The key of the pool module that was requested but not found or not set.
     */
    error NoModuleScheduled(bytes4 moduleKey);

    /**
     * @notice Error raised when attempting to set a zero address for a pool module.
     *
     * This error indicates that the provided `module` address is not a valid contract address.
     */
    error CannotSetZeroAddressForModule();

    /**
     * @notice Error raised when attempting to schedule a module update for a module key,
     * but there's already a pending scheduled update for the same module key.
     *
     * @param currentUpcomingModule The address of the currently scheduled upcoming module.
     *
     * @param scheduledSinceBlockTimestamp The block timestamp when the current upcoming module was scheduled.
     */
    error ModuleAlreadyScheduled(address currentUpcomingModule, uint256 scheduledSinceBlockTimestamp);

    /**
     * @notice Error raised when attempting to update a pool module before the scheduled delay has passed.
     *
     * @param requiredTimestamp The Unix timestamp when the scheduled module update can be activated.
     *
     * @param currentTimestamp The current Unix timestamp.
     */
    error ModuleUpdateNotReady(uint256 requiredTimestamp, uint256 currentTimestamp);

    /**
     * @notice Schedules an implementation update for a specific pool module type.
     *
     * This function registers a pending module update that can be activated later by calling
     * `updateModule` after the required delay period has passed. The delay serves as a safeguard
     * against malicious or accidental module replacements, ensuring that any update can be
     * reviewed or canceled before activation.
     *
     * @param newModule The address of the new `IPoolModule` implementation to be scheduled.
     * Cannot be the zero address. Its key (called via `[module].key()`) will be used to identify
     * which module to update.
     *
     * @dev Implementing contracts should restrict access to this function using OpenZeppelin's
     * `Ownable` or `AccessControl` to ensure only authorized accounts (e.g., protocol admins)
     * can schedule module updates.
     */
    function scheduleModule(IPoolModule newModule) external;

    /**
     * @notice Updates or finalizes a previously scheduled module implementation after the required delay has elapsed.
     *
     * This function activates the new `IPoolModule` implementation that was scheduled using `scheduleModule`.
     * It ensures that the delay period has passed before updating the current implementation, protecting the
     * protocol from rushed or potentially malicious updates.
     *
     * @param newModule The address of the new `IPoolModule` implementation to be set as the active module. Its
     * key (called via `[module].key()`) will be used to identify which module to update.
     *
     * @dev Implementing contracts should enforce proper access control over this function, such as using
     * OpenZeppelin's `Ownable` or `AccessControl` to restrict its usage to authorized accounts (e.g., protocol admins).
     */
    function updateModule(IPoolModule newModule) external;

    /**
     * @notice Cancels a previously scheduled module update before it becomes active.
     *
     * This function removes a pending scheduled module implementation for a given module address.
     * It can be used to revert a configuration mistake or prevent the activation of a potentially
     * unsafe or undesired module before the delay period expires.
     *
     * @param moduleToCancel The `IPoolModule` implementation whose scheduled update is to be canceled.
     * Its key (called via `[module].key()`) will be used to identify which scheduled module to cancel.
     *
     * @dev Implementing contracts should enforce proper access control over this function,
     * such as using OpenZeppelin's `Ownable` or `AccessControl` to restrict its usage to
     * authorized accounts (e.g., protocol admins).
     */
    function cancelScheduledModule(IPoolModule moduleToCancel) external;

    /**
     * @notice Returns the address of the current pool module for the given module key
     *
     * @param moduleKey The key of the pool module to retrieve
     *
     * @return moduleContract The address of the pool module for the given key
     */
    function getModule(bytes4 moduleKey) external view returns (address moduleContract);

    /**
     * @notice Returns the upcoming scheduled module for the given module key
     *
     * @param moduleKey The key of the pool module to retrieve the upcoming scheduled module for
     *
     * @return The UpcomingModule struct containing the scheduled module address and timestamp
     */
    function getUpcomingModule(bytes4 moduleKey) external view returns (UpcomingModule memory);
}
