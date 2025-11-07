// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

contract NetworkUtils {
    function getWrappedNativeAddress() external view returns (address wrappedNativeAddress) {
        if (block.chainid == 11155111) return 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

        revert("Unsupported or not configured network");
    }
}
