// SPDX-License-Identifier: GNU GPLv3
// solhint-disable
pragma solidity 0.8.30;

import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test} from "forge-std/Test.sol";
import {Modular, IModular, IPoolModule} from "../src/Modular.sol";
import {UniswapV3PoolModule} from "../src/modules/UniswapV3PoolModule.sol";

contract ModularInvariantTest is StdInvariant, Test {
    ModularHandler internal sut;

    function setUp() external {
        sut = new ModularHandler();
        targetContract(address(sut));
    }

    function invariant_ModuleShouldNeverUpdateBefore7DaysDelay() external view {
        assertEq(sut.getModule(sut.module().key()), address(0));
    }
}

contract ModularHandler is IModular, Test {
    IModular public realModular;
    IPoolModule public module;
    address public owner;

    constructor() {
        owner = msg.sender;
        realModular = new Modular(owner);
        module = new UniswapV3PoolModule();
    }

    function scheduleModule(IPoolModule newModule) external override {
        vm.prank(owner);
        realModular.scheduleModule(module);
    }

    function updateModule(IPoolModule newModule) external override {
        vm.prank(owner);
        realModular.updateModule(module);
    }

    function cancelScheduledModule(IPoolModule moduleToCancel) external override {
        vm.prank(owner);
        realModular.cancelScheduledModule(module);
    }

    function getModule(bytes4 moduleKey) external view override returns (address moduleContract) {
        return realModular.getModule(module.key());
    }

    function getUpcomingModule(bytes4 moduleKey) external view override returns (UpcomingModule memory) {
        return realModular.getUpcomingModule(module.key());
    }
}
