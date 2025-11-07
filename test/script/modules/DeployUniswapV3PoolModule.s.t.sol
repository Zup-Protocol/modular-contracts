// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployUniswapV3PoolModuleScript} from "../../../script/modules/DeployUniswapV3PoolModule.s.sol";
import {NetworkUtils} from "../../../script/deploy-utils/NetworkUtils.sol";
import {UniswapV3PoolModule} from "../../../src/modules/UniswapV3PoolModule.sol";
import {IUniswapV3PositionManager} from "../../../src/interfaces/IUniswapV3PositionManager.sol";
import {LiquidityActionRequest} from "../../../src/libraries/LiquidityActionRequest.sol";

contract DeployUniswapV3PoolModuleTest is Test {
    DeployUniswapV3PoolModuleScript internal sut;
    NetworkUtils internal networkUtils;

    function setUp() external {
        sut = new DeployUniswapV3PoolModuleScript();
        networkUtils = new NetworkUtils();
    }

    function test_deploy_usesCorrectWrappedNativeAddressForSepolia() external {
        vm.chainId(11155111);

        UniswapV3PoolModule module = UniswapV3PoolModule(sut.run());
        address expectedWrappedNativeAddress = networkUtils.getWrappedNativeAddress();
        address currentWrappedNativeAddress = module.i_wrappedNativeAddress();

        vm.assertEq(currentWrappedNativeAddress, expectedWrappedNativeAddress);
    }
}
