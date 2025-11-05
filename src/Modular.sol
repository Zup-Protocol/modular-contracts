// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {IPoolModule} from "./interfaces/IPoolModule.sol";
import {IModular} from "./interfaces/IModular.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Modular
 * @author Zup Protocol
 * @notice Core contract managing the modular architecture for liquidity pool interactions.
 *
 * The `Modular` contract coordinates and manages multiple pool module implementations,
 * each responsible for integrating with a specific DEX or liquidity protocol (e.g., Uniswap V3,
 * Aerodrome, PancakeSwap)
 *
 * The contract ensures consistent security and upgradeability through delayed updates,
 * preventing immediate replacement of modules and mitigating risks from misconfiguration
 * or malicious upgrades.
 *
 * @dev Implements the {IModular} interface and uses OpenZeppelin’s `Ownable2Step` for
 * secure ownership transfers and `ReentrancyGuard` for preventing reentrancy attacks.
 * Access to administrative functions is restricted to the contract owner.
 *
 * This contract should never hold user funds by design
 *
 * @custom:version 1.0.0
 */
contract Modular is IModular, Ownable2Step, ReentrancyGuard /* aderyn-ignore(centralization-risk) */ {
    using SafeERC20 for IERC20;

    mapping(bytes4 moduleKey => address module) private s_modules;
    mapping(bytes4 moduleKey => UpcomingModule module) private s_upcomingModules;

    /// @notice Initializes the Modular contract setting the owner to the provided address.
    /// @param moduleManager The address of the wallet that will manage modules defined in this contract.
    constructor(address moduleManager) Ownable(moduleManager) {}

    /// @inheritdoc IModular
    function scheduleModule(IPoolModule newModule) external onlyOwner /* aderyn-ignore(centralization-risk) */ {
        if (address(newModule) == address(0)) revert CannotSetZeroAddressForModule();

        // safe from reentrancy, as it only returns the module key without external calls
        bytes4 moduleKey = newModule.key(); // aderyn-fp(reentrancy-state-change)

        UpcomingModule memory currentUpcomingModule = s_upcomingModules[moduleKey];

        if (address(currentUpcomingModule.module) != address(0)) {
            revert ModuleAlreadyScheduled(currentUpcomingModule.module, currentUpcomingModule.sinceBlockTimestamp);
        }

        uint256 currentBlockTimestamp = block.timestamp;

        s_upcomingModules[moduleKey] = UpcomingModule({module: address(newModule), sinceBlockTimestamp: currentBlockTimestamp});

        emit ModuleScheduled(moduleKey, address(newModule), currentBlockTimestamp);
    }

    /// @inheritdoc IModular
    function updateModule(IPoolModule newModule) external override onlyOwner /* aderyn-ignore(centralization-risk) */ {
        // safe from reentrancy, as it only returns the module key without external calls
        bytes4 moduleKey = newModule.key(); // aderyn-ignore(reentrancy-state-change)

        UpcomingModule memory upcomingModule = s_upcomingModules[moduleKey];

        if (upcomingModule.module == address(0)) revert NoModuleScheduled(moduleKey);

        uint256 delayRequired = upcomingModule.sinceBlockTimestamp + 7 days;
        bool hasDelayPassed = block.timestamp > delayRequired;

        if (!hasDelayPassed) revert ModuleUpdateNotReady(delayRequired, block.timestamp);

        s_modules[moduleKey] = upcomingModule.module;
        delete s_upcomingModules[moduleKey];

        emit ModuleSet(moduleKey, upcomingModule.module);
    }

    /// @inheritdoc IModular
    function cancelScheduledModule(IPoolModule moduleToCancel) external onlyOwner /* aderyn-ignore(centralization-risk) */ {
        // safe from reentrancy, as it only returns the module key without external calls
        bytes4 moduleKey = moduleToCancel.key(); // aderyn-fp(reentrancy-state-change)

        delete s_upcomingModules[moduleKey];

        emit ScheduledModuleCanceled(moduleKey, address(moduleToCancel));
    }

    /// @inheritdoc IModular
    function getModule(bytes4 moduleKey) external view override returns (address moduleContract) {
        return s_modules[moduleKey];
    }

    /// @inheritdoc IModular
    function getUpcomingModule(bytes4 moduleKey) external view override returns (UpcomingModule memory) {
        return s_upcomingModules[moduleKey];
    }
}
