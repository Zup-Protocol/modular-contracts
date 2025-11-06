// SPDX-License-Identifier: GNU GPLv3
// solhint-disable
pragma solidity 0.8.30;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console} from "forge-std/Test.sol";
import {PoolModule, IPoolModule, LiquidityActionRequest} from "../src/PoolModule.sol";
import {ERC20Mock, ERC20} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PoolModuleInvariantTest is StdInvariant, Test {
    PoolModuleHandler internal sut;

    function setUp() external {
        sut = new PoolModuleHandler();
        targetContract(address(sut));
    }

    /// forge-config: default.invariant.fail-on-revert = true
    function invariant_contractNeverHoldAssets() external view {
        vm.assertEq(sut.transactionToken0().balanceOf(address(sut.realPoolModule())), 0, "Should not hold any token 0");
        vm.assertEq(sut.transactionToken1().balanceOf(address(sut.realPoolModule())), 0, "Should not hold any token 1");
        vm.assertEq(address(sut.realPoolModule()).balance, 0, "Should not hold any ETH");
    }
}

contract PoolModuleHandler is IPoolModule, Test {
    IPoolModule public realPoolModule;
    ERC20Mock public transactionToken0;
    ERC20Mock public transactionToken1;

    constructor() {
        transactionToken0 = new ERC20Mock();
        transactionToken1 = new ERC20Mock();
        realPoolModule = new PoolModuleTestImpl();
    }

    function addLiquidityWithNative(
        LiquidityActionRequest.LiquidityActionParams memory actionData,
        bytes calldata moduleData,
        uint256 value
    ) external payable {
        vm.assume(actionData.amount0 < value);
        vm.assume(actionData.amount1 < value);
        vm.assume(actionData.receiver != address(this));
        assumeUnusedAddress(actionData.receiver);
        assumeUnusedAddress(actionData.positionManager);

        actionData.token0 = address(0);
        actionData.token1 = address(0);

        vm.deal(address(this), value);
        realPoolModule.addLiquidity{value: value}(actionData, moduleData);
    }

    function addLiquidity(
        LiquidityActionRequest.LiquidityActionParams memory actionData,
        bytes calldata moduleData
    ) external payable override {
        vm.assume(actionData.receiver != address(this));
        assumeUnusedAddress(actionData.receiver);
        assumeUnusedAddress(actionData.positionManager);

        transactionToken0 = new ERC20Mock();
        transactionToken1 = new ERC20Mock();

        actionData.token0 = address(transactionToken0);
        actionData.token1 = address(transactionToken1);

        transactionToken0.mint(address(this), actionData.amount0);
        transactionToken1.mint(address(this), actionData.amount1);
        transactionToken0.approve(address(realPoolModule), actionData.amount0);
        transactionToken1.approve(address(realPoolModule), actionData.amount1);

        realPoolModule.addLiquidity{value: msg.value}(actionData, moduleData);
    }

    function key() external pure override returns (bytes4) {
        return bytes4(keccak256("XabasContract"));
    }

    function version() external pure override returns (string memory currentVersion) {
        return "21";
    }
}

contract PoolModuleTestImpl is PoolModule, Test {
    function key() external pure override returns (bytes4) {}

    function _executeAddLiquidity(
        LiquidityActionRequest.LiquidityActionParams memory actionParams,
        bytes calldata addLiquidityParams
    ) internal virtual override {}
}
