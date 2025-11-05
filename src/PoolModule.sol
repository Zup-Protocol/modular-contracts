// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {LiquidityActionRequest} from "./libraries/LiquidityActionRequest.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPoolModule} from "./interfaces/IPoolModule.sol";

/**
 * @title PoolModule
 * @author Zup Protocol
 * @notice Abstract base contract for implementing DEX pool modules.
 *
 * This contract provides a standardized framework for interacting with liquidity pools across different DEXs.
 * It handles common tasks such as token transfers, approvals, and native token refunds, while delegating
 * DEX-specific logic to the `_executeAddLiquidity` internal function, which must be implemented by child contracts.
 *
 * Implementing contracts should:
 * - Override `_executeAddLiquidity` to provide the actual liquidity addition logic for the specific DEX.
 */
abstract contract PoolModule is IPoolModule {
    using SafeERC20 for IERC20;

    fallback() external {
        revert UnsupportedModuleCall();
    }

    /// @inheritdoc IPoolModule
    function addLiquidity(LiquidityActionRequest.LiquidityActionParams calldata actionData, bytes calldata moduleData) external payable {
        bool isNative0 = actionData.token0 == address(0);
        bool isNative1 = actionData.token1 == address(0);

        if (!isNative0) {
            IERC20 token0 = IERC20(actionData.token0);
            token0.safeTransferFrom(msg.sender, address(this), actionData.amount0);
            token0.forceApprove(actionData.positionManager, actionData.amount0);
        }

        if (!isNative1) {
            IERC20 token1 = IERC20(actionData.token1);
            token1.safeTransferFrom(msg.sender, address(this), actionData.amount1);
            token1.forceApprove(actionData.positionManager, actionData.amount1);
        }

        _executeAddLiquidity(actionData, moduleData);

        if (address(this).balance > 0) Address.sendValue(payable(actionData.receiver), address(this).balance);

        if (!isNative0) {
            uint256 refundAmount0 = IERC20(actionData.token0).balanceOf(address(this));
            if (refundAmount0 > 0) IERC20(actionData.token0).safeTransfer(actionData.receiver, refundAmount0);
        }

        if (!isNative1) {
            uint256 refundAmount1 = IERC20(actionData.token1).balanceOf(address(this));
            if (refundAmount1 > 0) IERC20(actionData.token1).safeTransfer(actionData.receiver, refundAmount1);
        }

        emit LiquidityAdded(actionData.receiver, actionData.token0, actionData.token1, msg.sender, actionData.amount0, actionData.amount1);
    }

    /// @inheritdoc IPoolModule
    function key() external pure virtual returns (bytes4);

    /// @inheritdoc IPoolModule
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /**
     * @notice Executes the core logic for adding liquidity to the specific DEX.
     *
     * @dev This internal function is invoked by {addLiquidity} after all necessary token transfers and approvals
     * have been completed. Implementing contracts must override this function to provide the DEX-specific logic
     * required to add liquidity according to the module's requirements.
     *
     * Requirements:
     * - Must not emit {LiquidityAdded} or any other events; event emission is handled by {addLiquidity}.
     * - Must not handle refunds of native tokens to the sender; any excess ETH is refunded by {addLiquidity}.
     * But must ensure that any excess tokens are left in the contract for refunding.
     *
     * @param actionParams Standardized liquidity action parameters, including token addresses,
     * amounts, receiver, position manager, etc...
     *
     * @param addLiquidityParams ABI-encoded parameters specific to the DEX implementation. The expected
     * structure depends on the module being implemented.
     */
    function _executeAddLiquidity(
        LiquidityActionRequest.LiquidityActionParams memory actionParams,
        bytes calldata addLiquidityParams
    ) internal virtual;
}
