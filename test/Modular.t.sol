// SPDX-License-Identifier: GNU GPLv3
// solhint-disable
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {CommonBase} from "lib/forge-std/src/Base.sol";
import {IModular, Modular, IPoolModule, Ownable} from "../src/Modular.sol";

contract ModularTest is Test {
    IModular internal sut;
    address internal constant ADMIN = address(0xABCD);

    modifier asAdmin() {
        vm.prank(ADMIN);
        _;
        vm.stopPrank();
    }

    modifier scheduledModule(address newModule, bytes4 moduleKey) {
        assumeNotForgeAddress(newModule);
        assumeNotZeroAddress(newModule);

        vm.mockCall(address(newModule), abi.encodeWithSelector(IPoolModule.key.selector), abi.encode(moduleKey));

        vm.prank(ADMIN);
        sut.scheduleModule(IPoolModule(newModule));
        vm.stopPrank();
        _;
    }

    function setUp() external {
        hoax(ADMIN, 100 ether);
        sut = new Modular(ADMIN);
    }

    function testFuzz_scheduleModule_revertsWhenNotAdmin(address notAdmin, address newModule) external {
        vm.assume(notAdmin != ADMIN);
        vm.assume(newModule != address(0));

        vm.prank(notAdmin);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notAdmin));
        sut.scheduleModule(IPoolModule(newModule));

        vm.stopPrank();
    }

    function test_scheduleModule_revertsWhenZeroAddress() external asAdmin {
        vm.expectRevert(IModular.CannotSetZeroAddressForModule.selector);
        sut.scheduleModule(IPoolModule(address(0)));
    }

    function testFuzz_scheduleModule_revertsWhenSameModuleKeyAlreadyScheduled(address newModule, address newModule2) external asAdmin {
        assumeNotForgeAddress(newModule);
        assumeNotForgeAddress(newModule2);

        assumeNotZeroAddress(newModule);
        assumeNotZeroAddress(newModule2);

        vm.mockCall(address(newModule), abi.encodeWithSelector(IPoolModule.key.selector), abi.encode(bytes4(keccak256("uniswap-v3"))));
        vm.mockCall(address(newModule2), abi.encodeWithSelector(IPoolModule.key.selector), abi.encode(bytes4(keccak256("uniswap-v3"))));

        uint256 scheduledSinceBlockTimestamp = block.timestamp;
        sut.scheduleModule(IPoolModule(newModule));

        vm.prank(ADMIN);

        vm.expectRevert(abi.encodeWithSelector(IModular.ModuleAlreadyScheduled.selector, newModule, scheduledSinceBlockTimestamp));
        sut.scheduleModule(IPoolModule(newModule2));

        vm.stopPrank();
    }

    function testFuzz_scheduleModule_notRevertWhenOtherModuleKeyAlreadyScheduled(address newModule, address newModule2) external asAdmin {
        assumeNotForgeAddress(newModule);
        assumeNotForgeAddress(newModule2);
        assumeNotZeroAddress(newModule);
        assumeNotZeroAddress(newModule2);

        vm.assume(newModule != newModule2);

        vm.mockCall(address(newModule), abi.encodeWithSelector(IPoolModule.key.selector), abi.encode(bytes4(keccak256("uniswap-v3"))));
        vm.mockCall(address(newModule2), abi.encodeWithSelector(IPoolModule.key.selector), abi.encode(bytes4(keccak256("UNISWAP_V4"))));

        sut.scheduleModule(IPoolModule(newModule));

        vm.prank(ADMIN);
        sut.scheduleModule(IPoolModule(newModule2));
        vm.stopPrank();
    }

    function testFuzz_scheduleModule_savesUpcomingModuleAndTimestamp(address newModule, uint256 blockTimestamp) external asAdmin {
        assumeNotForgeAddress(newModule);
        assumeNotZeroAddress(newModule);
        bytes4 moduleKey = bytes4(keccak256("uniswap-v3"));

        vm.mockCall(address(newModule), abi.encodeWithSelector(IPoolModule.key.selector), abi.encode(moduleKey));
        vm.warp(blockTimestamp);

        sut.scheduleModule(IPoolModule(newModule));

        IModular.UpcomingModule memory savedUpcomingModule = sut.getUpcomingModule(moduleKey);

        assertEq(savedUpcomingModule.module, newModule);
        assertGe(savedUpcomingModule.sinceBlockTimestamp, blockTimestamp);
    }

    function testFuzz_scheduleModule_emitsEventWithCorrectParameters(
        bytes4 moduleKey,
        address newModule,
        uint256 blockTimestamp
    ) external asAdmin {
        assumeNotForgeAddress(newModule);
        assumeNotZeroAddress(newModule);

        vm.mockCall(address(newModule), abi.encodeWithSelector(IPoolModule.key.selector), abi.encode(moduleKey));
        vm.warp(blockTimestamp);

        vm.expectEmit(true, true, true, true);
        emit IModular.ModuleScheduled(moduleKey, newModule, blockTimestamp);

        sut.scheduleModule(IPoolModule(newModule));
    }

    function testFuzz_updateModule_revertsWhenNotAdmin(address notAdmin, address newModule) external {
        vm.assume(notAdmin != ADMIN);
        vm.assume(newModule != address(0));

        vm.prank(notAdmin);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notAdmin));
        sut.updateModule(IPoolModule(newModule));

        vm.stopPrank();
    }

    function testFuzz_updateModule_revertsWhenNoModuleScheduled(address newModule) external asAdmin {
        assumeNotForgeAddress(newModule);
        assumeNotZeroAddress(newModule);

        vm.mockCall(address(newModule), abi.encodeWithSelector(IPoolModule.key.selector), abi.encode(bytes4(keccak256("uniswap-v3"))));

        vm.expectRevert(abi.encodeWithSelector(IModular.NoModuleScheduled.selector, bytes4(keccak256("uniswap-v3"))));
        sut.updateModule(IPoolModule(newModule));
    }

    function testFuzz_updateModule_revertsWhenDelayNotPassed7Days(
        address newModule
    ) external scheduledModule(newModule, bytes4(keccak256("uniswap-v3"))) asAdmin {
        uint256 requiredTimestamp = block.timestamp + 7 days;
        uint256 currentTimestamp = block.timestamp + 6 days;
        vm.warp(currentTimestamp);

        vm.expectRevert(abi.encodeWithSelector(IModular.ModuleUpdateNotReady.selector, requiredTimestamp, currentTimestamp));
        sut.updateModule(IPoolModule(newModule));
    }

    function testFuzz_updateModule_savesModuleAndDeletesUpcomingModule(
        address newModule,
        bytes4 moduleKey
    ) external scheduledModule(newModule, moduleKey) asAdmin {
        uint256 warpTo = block.timestamp + 8 days;
        vm.warp(warpTo);

        assert(sut.getModule(moduleKey) != newModule);

        vm.prank(ADMIN);
        sut.updateModule(IPoolModule(newModule));
        vm.stopPrank();

        address savedModule = sut.getModule(moduleKey);
        IModular.UpcomingModule memory upcomingModule = sut.getUpcomingModule(moduleKey);

        assertEq(savedModule, newModule);
        assertEq(upcomingModule.module, address(0));
        assertEq(upcomingModule.sinceBlockTimestamp, 0);
    }

    function testFuzz_updateModule_emitsEventWithCorrectParameters(
        address newModule,
        bytes4 moduleKey
    ) external scheduledModule(newModule, moduleKey) asAdmin {
        uint256 warpTo = block.timestamp + 8 days;
        vm.warp(warpTo);

        vm.expectEmit(true, true, false, false);
        emit IModular.ModuleSet(moduleKey, newModule);

        sut.updateModule(IPoolModule(newModule));
    }

    function testFuzz_cancelScheduledModule_revertsWhenNotAdmin(address notAdmin, address moduleToCancel) external {
        vm.assume(notAdmin != ADMIN);
        vm.assume(moduleToCancel != address(0));

        vm.prank(notAdmin);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notAdmin));
        sut.cancelScheduledModule(IPoolModule(moduleToCancel));

        vm.stopPrank();
    }

    function testFuzz_cancelScheduledModule_deletesUpcomingModule(
        address moduleToCancel,
        bytes4 moduleKey
    ) external scheduledModule(moduleToCancel, moduleKey) asAdmin {
        sut.cancelScheduledModule(IPoolModule(moduleToCancel));

        IModular.UpcomingModule memory upcomingModule = sut.getUpcomingModule(moduleKey);

        assertEq(upcomingModule.module, address(0));
        assertEq(upcomingModule.sinceBlockTimestamp, 0);
    }

    function testFuzz_cancelScheduledModule_emitsEventWithCorrectParameters(
        address moduleToCancel,
        bytes4 moduleKey
    ) external scheduledModule(moduleToCancel, moduleKey) asAdmin {
        vm.expectEmit(true, true, false, false);
        emit IModular.ScheduledModuleCanceled(moduleKey, moduleToCancel);

        sut.cancelScheduledModule(IPoolModule(moduleToCancel));
    }

    function testFuzz_getModule_returnsCorrectModuleAddress(
        address newModule,
        bytes4 moduleKey
    ) external scheduledModule(newModule, moduleKey) asAdmin {
        uint256 warpTo = block.timestamp + 8 days;
        vm.warp(warpTo);

        sut.updateModule(IPoolModule(newModule));

        address savedModule = sut.getModule(moduleKey);

        assertEq(savedModule, newModule);
    }

    function testFuzz_getUpcomingModule_returnsCorrectUpcomingModule(
        address newModule,
        bytes4 moduleKey
    ) external scheduledModule(newModule, moduleKey) asAdmin {
        IModular.UpcomingModule memory upcomingModule = sut.getUpcomingModule(moduleKey);

        assertEq(upcomingModule.module, newModule);
        assertGe(upcomingModule.sinceBlockTimestamp, block.timestamp - 1);
    }
}
