// SPDX-License-Identifier: GNU GPLv3
// solhint-disable
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {PoolModule, IPoolModule, LiquidityActionRequest} from "../src/PoolModule.sol";
import {ERC20Mock, ERC20} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PoolModuleTest is Test {
    PoolModuleTestImpl internal _poolModule;

    function setUp() external {
        _poolModule = new PoolModuleTestImpl();

        vm.deal(address(this), type(uint256).max);
    }

    function test_unknownFunctionSelectorCallReverts() external {
        (, bytes memory data) = address(_poolModule).call(abi.encodeWithSelector(bytes4(keccak256("unknownFunction()"))));

        assertEq(data, abi.encodeWithSelector(IPoolModule.UnsupportedModuleCall.selector));
    }

    function testFuzz_addLiquidity_transferFundsFromSender(uint128 amount0, uint128 amount1) external {
        ERC20Mock token0 = new ERC20Mock();
        ERC20Mock token1 = new ERC20Mock();

        address token0Address = address(token0);
        address token1Address = address(token1);
        address positionManager = address(0x3);
        address receiver = address(0x4);

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(_poolModule), amount0);
        token1.approve(address(_poolModule), amount1);

        LiquidityActionRequest.LiquidityActionParams memory actionParams = LiquidityActionRequest.LiquidityActionParams({
            token0: token0Address,
            token1: token1Address,
            positionManager: positionManager,
            receiver: receiver,
            amount0: amount0,
            amount1: amount1
        });

        vm.expectCall(
            token0Address,
            abi.encodeWithSelector(ERC20.transferFrom.selector, address(this), address(_poolModule), uint256(amount0))
        );

        vm.expectCall(
            token1Address,
            abi.encodeWithSelector(ERC20.transferFrom.selector, address(this), address(_poolModule), uint256(amount1))
        );

        _poolModule.addLiquidity(actionParams, "");
    }

    function testFuzz_addLiquidity_approveTokensForPositionManager(
        LiquidityActionRequest.LiquidityActionParams memory actionParams
    ) external {
        ERC20Mock token0 = new ERC20Mock();
        ERC20Mock token1 = new ERC20Mock();

        assumeNotZeroAddress(actionParams.receiver);
        assumeNotZeroAddress(actionParams.positionManager);

        actionParams.token0 = address(token0);
        actionParams.token1 = address(token1);

        token0.mint(address(this), actionParams.amount0);
        token1.mint(address(this), actionParams.amount1);
        token0.approve(address(_poolModule), actionParams.amount0);
        token1.approve(address(_poolModule), actionParams.amount1);

        vm.expectCall(
            actionParams.token0,
            abi.encodeWithSelector(ERC20.approve.selector, address(actionParams.positionManager), uint256(actionParams.amount0))
        );

        vm.expectCall(
            actionParams.token1,
            abi.encodeWithSelector(ERC20.approve.selector, address(actionParams.positionManager), uint256(actionParams.amount1))
        );

        _poolModule.addLiquidity(actionParams, "");
    }

    function testFuzz_addLiquidity_notTransferToken0FromSenderIfNative(uint128 amount0, uint128 amount1) external {
        ERC20Mock token1 = new ERC20Mock();

        address token0Address = address(0);
        address token1Address = address(token1);
        address positionManager = address(0x3);
        address receiver = address(0x4);

        token1.mint(address(this), amount1);
        token1.approve(address(_poolModule), amount1);

        LiquidityActionRequest.LiquidityActionParams memory actionParams = LiquidityActionRequest.LiquidityActionParams({
            token0: token0Address,
            token1: token1Address,
            positionManager: positionManager,
            receiver: receiver,
            amount0: amount0,
            amount1: amount1
        });

        vm.mockCallRevert(
            token0Address,
            abi.encodeWithSelector(ERC20.transferFrom.selector, address(this), address(_poolModule), uint256(amount0)),
            "should not be called"
        );

        _poolModule.addLiquidity{value: amount0}(actionParams, "");
    }

    function testFuzz_addLiquidity_notTransferToken1FromSenderIfNative(uint128 amount0, uint128 amount1) external {
        ERC20Mock token0 = new ERC20Mock();

        address token0Address = address(token0);
        address token1Address = address(0);
        address positionManager = address(0x3);
        address receiver = address(0x4);

        token0.mint(address(this), amount0);
        token0.approve(address(_poolModule), amount0);

        LiquidityActionRequest.LiquidityActionParams memory actionParams = LiquidityActionRequest.LiquidityActionParams({
            token0: token0Address,
            token1: token1Address,
            positionManager: positionManager,
            receiver: receiver,
            amount0: amount0,
            amount1: amount1
        });

        vm.mockCallRevert(
            token1Address,
            abi.encodeWithSelector(ERC20.transferFrom.selector, address(this), address(_poolModule), uint256(amount1)),
            "should not be called"
        );

        _poolModule.addLiquidity{value: amount1}(actionParams, "");
    }

    function test_addLiquidity_shouldCallExecuteLiquidityImplementationWithActionParams() external {
        ERC20Mock token0 = new ERC20Mock();
        ERC20Mock token1 = new ERC20Mock();

        address token0Address = address(token0);
        address token1Address = address(token1);
        address positionManager = address(0x3);
        address receiver = address(0x4);

        token0.mint(address(this), 1);
        token1.mint(address(this), 1);
        token0.approve(address(_poolModule), 1);
        token1.approve(address(_poolModule), 1);

        LiquidityActionRequest.LiquidityActionParams memory actionParams = LiquidityActionRequest.LiquidityActionParams({
            token0: token0Address,
            token1: token1Address,
            positionManager: positionManager,
            receiver: receiver,
            amount0: 1,
            amount1: 1
        });

        _poolModule.addLiquidity(actionParams, "");

        (LiquidityActionRequest.LiquidityActionParams memory actionParamsSent, ) = _poolModule.executeAddLiquidityCallParams();

        assertEq(abi.encode(actionParamsSent), abi.encode(actionParams));
    }

    function test_addLiquidity_shouldCallExecuteLiquidityImplementationWithModuleParams() external {
        ERC20Mock token0 = new ERC20Mock();
        ERC20Mock token1 = new ERC20Mock();

        address token0Address = address(token0);
        address token1Address = address(token1);
        address positionManager = address(0x3);
        address receiver = address(0x4);

        token0.mint(address(this), 1);
        token1.mint(address(this), 1);
        token0.approve(address(_poolModule), 1);
        token1.approve(address(_poolModule), 1);

        LiquidityActionRequest.LiquidityActionParams memory actionParams = LiquidityActionRequest.LiquidityActionParams({
            token0: token0Address,
            token1: token1Address,
            positionManager: positionManager,
            receiver: receiver,
            amount0: 1,
            amount1: 1
        });

        bytes memory moduleParams = abi.encode(32, "test", false);

        _poolModule.addLiquidity(actionParams, moduleParams);

        (, bytes memory moduleParamsSent) = _poolModule.executeAddLiquidityCallParams();
        assertEq(abi.encode(moduleParamsSent), abi.encode(moduleParams));
    }

    function testFuzz_addLiquidity_shouldSendAnyRemainingNativeFundsToReceiver(
        LiquidityActionRequest.LiquidityActionParams memory actionParams
    ) external {
        actionParams.token0 = address(0);
        actionParams.token1 = address(0);

        assumeUnusedAddress(actionParams.receiver);

        vm.assume(actionParams.amount0 < type(uint64).max);
        vm.assume(actionParams.amount1 < type(uint64).max);

        uint256 nativeAmountSent = (actionParams.amount0 + actionParams.amount1) * (10 ** 18);
        uint256 nativeAmountInTheContract = type(uint64).max;

        vm.deal(address(this), (nativeAmountSent));
        vm.deal(address(_poolModule), nativeAmountInTheContract);

        uint256 receiverBalanceBefore = address(actionParams.receiver).balance;

        _poolModule.addLiquidity{value: nativeAmountSent}(actionParams, "");

        assertEq(address(_poolModule).balance, 0);
        assertEq(address(actionParams.receiver).balance, receiverBalanceBefore + nativeAmountSent + nativeAmountInTheContract);
    }

    function testFuzz_addLiquidity_shouldSendAnyRemainingERC20FundsToReceiver(
        LiquidityActionRequest.LiquidityActionParams memory actionParams,
        uint64 amount0inThePoolModule,
        uint64 amount1inThePoolModule
    ) external {
        assumeUnusedAddress(actionParams.receiver);
        assumeNotZeroAddress(actionParams.positionManager);

        ERC20Mock token0Erc20 = new ERC20Mock();
        ERC20Mock token1Erc20 = new ERC20Mock();

        token0Erc20.mint(address(this), actionParams.amount0);
        token1Erc20.mint(address(this), actionParams.amount1);

        token0Erc20.mint(address(_poolModule), amount0inThePoolModule);
        token1Erc20.mint(address(_poolModule), amount1inThePoolModule);

        token0Erc20.approve(address(_poolModule), actionParams.amount0);
        token1Erc20.approve(address(_poolModule), actionParams.amount1);

        actionParams.token0 = address(token0Erc20);
        actionParams.token1 = address(token1Erc20);

        vm.assume(actionParams.amount0 < type(uint64).max);
        vm.assume(actionParams.amount1 < type(uint64).max);

        _poolModule.addLiquidity(actionParams, "");

        assertEq(token0Erc20.balanceOf(address(_poolModule)), 0, "All remaining token 0 should be sent to the receiver");

        assertEq(token1Erc20.balanceOf(address(_poolModule)), 0, "All remaining token 1 should be sent to the receiver");

        assertEq(
            token0Erc20.balanceOf(address(actionParams.receiver)),
            actionParams.amount0 + amount0inThePoolModule,
            "The balance of the receiver should be equal to the unused token0 amount + the amount already in the pool module"
        );

        assertEq(
            token1Erc20.balanceOf(address(actionParams.receiver)),
            actionParams.amount1 + amount1inThePoolModule,
            "The balance of the receiver should be equal to the unused token1 amount + the amount already in the pool module"
        );
    }

    function testFuzz_addLiquidity_emitsEventWithCorrectParameters(
        LiquidityActionRequest.LiquidityActionParams memory actionParams,
        address sender
    ) external {
        assumeUnusedAddress(actionParams.receiver);
        assumeNotZeroAddress(actionParams.positionManager);
        assumeNotZeroAddress(sender);

        ERC20Mock token0Erc20 = new ERC20Mock();
        ERC20Mock token1Erc20 = new ERC20Mock();

        vm.startPrank(sender);

        token0Erc20.mint(sender, actionParams.amount0);
        token1Erc20.mint(sender, actionParams.amount1);

        token0Erc20.approve(address(_poolModule), actionParams.amount0);
        token1Erc20.approve(address(_poolModule), actionParams.amount1);

        actionParams.token0 = address(token0Erc20);
        actionParams.token1 = address(token1Erc20);

        vm.expectEmit(true, true, true, true);
        emit IPoolModule.LiquidityAdded(
            actionParams.receiver,
            actionParams.token0,
            actionParams.token1,
            sender,
            actionParams.amount0,
            actionParams.amount1
        );

        _poolModule.addLiquidity(actionParams, "");
        vm.stopPrank();
    }

    function test_revertsWhenSendingNativeToContract() external {
        vm.expectRevert(IPoolModule.NativeTransferNotAllowed.selector);
        payable(_poolModule).transfer(1);
    }

    function testFuzz_addLiquidity_revertsSendingLessNativeThanRequiredForToken0(uint128 amount0Needed, uint128 amount0Sent) external {
        vm.assume(amount0Needed > amount0Sent);

        ERC20Mock token1Erc20 = new ERC20Mock();

        token1Erc20.mint(address(this), 1);
        token1Erc20.approve(address(_poolModule), 1);

        LiquidityActionRequest.LiquidityActionParams memory actionParams = LiquidityActionRequest.LiquidityActionParams({
            token0: address(0),
            token1: address(token1Erc20),
            amount0: uint128(amount0Needed),
            amount1: 1,
            receiver: address(this),
            positionManager: address(_poolModule)
        });

        vm.expectRevert(abi.encodeWithSelector(IPoolModule.NotEnoughNativeValue.selector, amount0Needed, amount0Sent));
        _poolModule.addLiquidity{value: amount0Sent}(actionParams, "");
    }

    function testFuzz_addLiquidity_revertsSendingLessNativeThanRequiredForToken1(uint128 amount1Needed, uint128 amount1Sent) external {
        vm.assume(amount1Needed > amount1Sent);

        ERC20Mock token0Erc20 = new ERC20Mock();

        token0Erc20.mint(address(this), 1);
        token0Erc20.approve(address(_poolModule), 1);

        LiquidityActionRequest.LiquidityActionParams memory actionParams = LiquidityActionRequest.LiquidityActionParams({
            token0: address(token0Erc20),
            token1: address(0),
            amount0: 1,
            amount1: uint128(amount1Needed),
            receiver: address(this),
            positionManager: address(_poolModule)
        });

        vm.expectRevert(abi.encodeWithSelector(IPoolModule.NotEnoughNativeValue.selector, amount1Needed, amount1Sent));
        _poolModule.addLiquidity{value: amount1Sent}(actionParams, "");
    }

    function test_addLiquidity_allowsContractReceiveNative() external {
        ERC20Mock token0Erc20 = new ERC20Mock();
        ERC20Mock token1Erc20 = new ERC20Mock();

        LiquidityActionRequest.LiquidityActionParams memory actionParams = LiquidityActionRequest.LiquidityActionParams({
            token0: address(token0Erc20),
            token1: address(token1Erc20),
            positionManager: address(21),
            receiver: address(22),
            amount0: 1,
            amount1: 1
        });

        token0Erc20.mint(address(this), actionParams.amount0);
        token1Erc20.mint(address(this), actionParams.amount1);

        token0Erc20.approve(address(_poolModule), actionParams.amount0);
        token1Erc20.approve(address(_poolModule), actionParams.amount1);

        actionParams.token0 = address(token0Erc20);
        actionParams.token1 = address(token1Erc20);

        _poolModule.setShouldSendETHBack();
        _poolModule.addLiquidity(actionParams, "");

        // if it doesn't revert, the test passed
    }

    function test_key_returnsImplementationContractKey() external {
        assertEq(_poolModule.key(), new PoolModuleTestImpl().key());
    }

    function test_version_returnsCurrentVersion() external view {
        assertEq(_poolModule.version(), "1.0.0");
    }
}

contract PoolModuleTestImpl is PoolModule, Test {
    constructor() PoolModule() {}

    bool public shouldSendETHBack = false;

    struct ExecuteAddLiquidityParams {
        LiquidityActionRequest.LiquidityActionParams actionParams;
        bytes addLiquidityParams;
    }

    ExecuteAddLiquidityParams public executeAddLiquidityCallParams;

    function setShouldSendETHBack() external {
        shouldSendETHBack = true;
    }

    function key() external pure override returns (bytes4) {
        return bytes4(keccak256("XabasContract"));
    }

    function _executeAddLiquidity(
        LiquidityActionRequest.LiquidityActionParams memory actionParams,
        bytes calldata addLiquidityParams
    ) internal virtual override {
        executeAddLiquidityCallParams = ExecuteAddLiquidityParams({actionParams: actionParams, addLiquidityParams: addLiquidityParams});
        if (shouldSendETHBack) payable(this).transfer(msg.value);
    }
}
