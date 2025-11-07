// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {UniswapV3PoolModule} from "../../src/modules/UniswapV3PoolModule.sol";
import {NetworkUtils} from "../deploy-utils/NetworkUtils.sol";

contract DeployUniswapV3PoolModuleScript is Script {
    function run() external returns (UniswapV3PoolModule module) {
        NetworkUtils networkUtils = new NetworkUtils();

        vm.startBroadcast();
        module = new UniswapV3PoolModule{salt: keccak256("uniswap-v3")}({wrappedNativeAddress: networkUtils.getWrappedNativeAddress()});
        vm.stopBroadcast();
    }
}
