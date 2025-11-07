// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {NetworkUtils} from "../../script/deploy-utils/NetworkUtils.sol";

contract NetworkUtilsTest is Test {
    NetworkUtils internal sut;

    function setUp() external {
        sut = new NetworkUtils();
    }

    function test_getWrappedNativeAddress_returnsCorrectAddressForSepolia() external {
        vm.chainId(11155111);

        address wrappedNativeAddress = sut.getWrappedNativeAddress();
        assert(wrappedNativeAddress == 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14);
    }

    function test_getWrappedNativeAddress_revertsForUnsupportedNetwork() external {
        vm.chainId(189216892612619);

        vm.expectRevert("Unsupported or not configured network");
        sut.getWrappedNativeAddress();
    }
}
