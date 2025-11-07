// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV3PoolModule, LiquidityActionRequest, IUniswapV3PositionManager} from "../../src/modules/UniswapV3PoolModule.sol";
import {UniswapV3PositionManagerMock} from "../test-utils/mocks.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract UniswapV3PoolModuleTest is Test {
    UniswapV3PoolModule internal uniswapV3PoolModule;
    IUniswapV3PositionManager internal positionManager;
    ERC20Mock internal mockToken0;
    ERC20Mock internal mockToken1;
    address internal wrappedNativeAddress;

    function setUp() external {
        wrappedNativeAddress = address(36918);
        uniswapV3PoolModule = new UniswapV3PoolModule({wrappedNativeAddress: wrappedNativeAddress});
        positionManager = new UniswapV3PositionManagerMock();
        mockToken0 = new ERC20Mock();
        mockToken1 = new ERC20Mock();
    }

    function test_key_returnsTheCorrectValue() external view {
        assert(uniswapV3PoolModule.key() == bytes4(keccak256("uniswap-v3")));
    }

    function testFuzz_addLiquidity_callUniswapV3PositionManagerWithPassedParams(
        LiquidityActionRequest.LiquidityActionParams memory actionData,
        LiquidityActionRequest.UniswapV3AddLiquidityParams calldata moduleData
    ) external {
        assumeUnusedAddress(actionData.receiver);
        assumeUnusedAddress(actionData.positionManager);
        assumeUnusedAddress(actionData.token0);
        assumeUnusedAddress(actionData.token1);

        actionData.positionManager = address(positionManager);
        actionData.token0 = address(mockToken0);
        actionData.token1 = address(mockToken1);

        mockToken0.mint(address(this), actionData.amount0);
        mockToken1.mint(address(this), actionData.amount1);
        mockToken0.approve(address(uniswapV3PoolModule), actionData.amount0);
        mockToken1.approve(address(uniswapV3PoolModule), actionData.amount1);

        vm.expectCall(
            actionData.positionManager,
            abi.encodeWithSelector(
                IUniswapV3PositionManager.mint.selector,
                (
                    IUniswapV3PositionManager.MintParams({
                        token0: actionData.token0,
                        token1: actionData.token1,
                        amount0Desired: actionData.amount0,
                        amount1Desired: actionData.amount1,
                        fee: moduleData.fee,
                        tickLower: moduleData.tickLower,
                        tickUpper: moduleData.tickUpper,
                        amount0Min: moduleData.amount0Min,
                        amount1Min: moduleData.amount1Min,
                        recipient: address(actionData.receiver),
                        deadline: moduleData.deadline
                    })
                )
            )
        );
        uniswapV3PoolModule.addLiquidity(actionData, abi.encode(moduleData));
    }

    function testFuzz_addLiquidity_forwardNativeAmountToPositionManager(
        LiquidityActionRequest.LiquidityActionParams memory actionData,
        LiquidityActionRequest.UniswapV3AddLiquidityParams calldata moduleData
    ) external {
        assumeUnusedAddress(actionData.receiver);
        assumeUnusedAddress(actionData.positionManager);
        vm.assume(actionData.amount0 < type(uint64).max);
        vm.assume(actionData.amount1 < type(uint64).max);

        actionData.positionManager = address(positionManager);
        actionData.token0 = address(0);
        actionData.token1 = address(0);

        uint256 nativeAmountSent = (actionData.amount0 + actionData.amount1) * (10 ** 18);
        vm.deal(address(this), nativeAmountSent);

        vm.expectCall(
            actionData.positionManager,
            nativeAmountSent,
            abi.encodeWithSelector(
                IUniswapV3PositionManager.mint.selector,
                (
                    IUniswapV3PositionManager.MintParams({
                        token0: wrappedNativeAddress,
                        token1: wrappedNativeAddress,
                        amount0Desired: actionData.amount0,
                        amount1Desired: actionData.amount1,
                        fee: moduleData.fee,
                        tickLower: moduleData.tickLower,
                        tickUpper: moduleData.tickUpper,
                        amount0Min: moduleData.amount0Min,
                        amount1Min: moduleData.amount1Min,
                        recipient: address(actionData.receiver),
                        deadline: moduleData.deadline
                    })
                )
            )
        );
        uniswapV3PoolModule.addLiquidity{value: nativeAmountSent}(actionData, abi.encode(moduleData));
    }

    function test_addLiquidity_setWrappedNativeIfNativeForPositionManager(address customWrappedNativeAddress) external {
        assumeNotZeroAddress(customWrappedNativeAddress);

        uniswapV3PoolModule = new UniswapV3PoolModule(customWrappedNativeAddress);
        vm.deal(address(this), 1 ether);

        LiquidityActionRequest.LiquidityActionParams memory actionData = LiquidityActionRequest.LiquidityActionParams({
            token0: address(0),
            token1: address(0),
            positionManager: address(positionManager),
            receiver: address(21),
            amount0: 1000,
            amount1: 1000
        });

        LiquidityActionRequest.UniswapV3AddLiquidityParams memory moduleData = LiquidityActionRequest.UniswapV3AddLiquidityParams({
            fee: 0,
            tickLower: 0,
            tickUpper: 0,
            amount0Min: 0,
            amount1Min: 0,
            deadline: 0
        });

        vm.expectCall(
            actionData.positionManager,
            1 ether,
            abi.encodeWithSelector(
                IUniswapV3PositionManager.mint.selector,
                (
                    IUniswapV3PositionManager.MintParams({
                        token0: customWrappedNativeAddress,
                        token1: customWrappedNativeAddress,
                        amount0Desired: actionData.amount0,
                        amount1Desired: actionData.amount1,
                        fee: moduleData.fee,
                        tickLower: moduleData.tickLower,
                        tickUpper: moduleData.tickUpper,
                        amount0Min: moduleData.amount0Min,
                        amount1Min: moduleData.amount1Min,
                        recipient: address(actionData.receiver),
                        deadline: moduleData.deadline
                    })
                )
            )
        );
        uniswapV3PoolModule.addLiquidity{value: 1 ether}(actionData, abi.encode(moduleData));
    }

    function test_deploy_revertsIfWrappedNativeIsZero() external {
        vm.expectRevert(UniswapV3PoolModule.WrappedNativeCannotBeZeroAddress.selector);
        new UniswapV3PoolModule(address(0));
    }

    function test_addLiquidity_callsRefundETHOnPositionManagerWhenNativeAmountSent() external {
        vm.deal(address(this), 1 ether);

        vm.expectCall(address(positionManager), abi.encodeWithSelector(IUniswapV3PositionManager.refundETH.selector));
        uniswapV3PoolModule.addLiquidity{value: 1 ether}(
            LiquidityActionRequest.LiquidityActionParams({
                token0: address(0),
                token1: address(0),
                positionManager: address(positionManager),
                receiver: address(21),
                amount0: 1000,
                amount1: 1000
            }),
            abi.encode(
                LiquidityActionRequest.UniswapV3AddLiquidityParams({
                    fee: 0,
                    tickLower: 0,
                    tickUpper: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: 0
                })
            )
        );
    }

    function test_addLiquidity_doesNotCallRefundETHOnPositionManagerWhenNativeNotSent() external {
        vm.mockCallRevert(
            address(positionManager),
            abi.encodeWithSelector(IUniswapV3PositionManager.refundETH.selector),
            "should not be called"
        );
        uniswapV3PoolModule.addLiquidity(
            LiquidityActionRequest.LiquidityActionParams({
                token0: address(0),
                token1: address(0),
                positionManager: address(positionManager),
                receiver: address(21),
                amount0: 0,
                amount1: 0
            }),
            abi.encode(
                LiquidityActionRequest.UniswapV3AddLiquidityParams({
                    fee: 0,
                    tickLower: 0,
                    tickUpper: 0,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: 0
                })
            )
        );
    }
}
