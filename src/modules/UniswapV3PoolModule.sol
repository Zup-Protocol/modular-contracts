// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {PoolModule} from "../PoolModule.sol";
import {LiquidityActionRequest} from "../libraries/LiquidityActionRequest.sol";
import {IUniswapV3PositionManager} from "../interfaces/IUniswapV3PositionManager.sol";

/**
 *  @title A Uniswap V3 Pool Module
 *  @author Zup Protocol (https://zupprotocol.xyz)
 *  @notice Provides functions to interact with Uniswap V3-style pools.
 *  any DEX that inherit Uniswap V3 architecture can use this module
 *
 * @custom:version 1.0.0
 *
 */
contract UniswapV3PoolModule is PoolModule /* aderyn-fp(contract-locks-ether) */ {
    /// @notice The address of the wrapped native token of the network, e.g. WETH
    address public immutable i_wrappedNativeAddress;

    error WrappedNativeCannotBeZeroAddress();

    constructor(address wrappedNativeAddress) {
        if (wrappedNativeAddress == address(0)) revert WrappedNativeCannotBeZeroAddress();

        i_wrappedNativeAddress = wrappedNativeAddress;
    }

    /// @inheritdoc PoolModule
    function key() external pure override returns (bytes4) {
        return bytes4(keccak256("uniswap-v3"));
    }

    /// @inheritdoc PoolModule
    function _executeAddLiquidity(
        LiquidityActionRequest.LiquidityActionParams memory actionParams,
        bytes calldata addLiquidityParams
    ) internal override {
        LiquidityActionRequest.UniswapV3AddLiquidityParams memory requestData = abi.decode(
            addLiquidityParams,
            (LiquidityActionRequest.UniswapV3AddLiquidityParams)
        );

        IUniswapV3PositionManager positionManager = IUniswapV3PositionManager(actionParams.positionManager);

        //slither-disable-next-line unused-return
        positionManager.mint{value: msg.value}(
            IUniswapV3PositionManager.MintParams({
                // as uniswap v3 doesn't support native, we need to use the wrapped native address.
                token0: actionParams.token0 == address(0) ? i_wrappedNativeAddress : actionParams.token0,
                token1: actionParams.token1 == address(0) ? i_wrappedNativeAddress : actionParams.token1,
                amount0Desired: actionParams.amount0,
                amount1Desired: actionParams.amount1,
                fee: requestData.fee,
                tickLower: requestData.tickLower,
                tickUpper: requestData.tickUpper,
                amount0Min: requestData.amount0Min,
                amount1Min: requestData.amount1Min,
                recipient: address(actionParams.receiver),
                deadline: requestData.deadline
            })
        );

        if (msg.value > 0) positionManager.refundETH();
    }
}
