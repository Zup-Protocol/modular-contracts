// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {IModular, Modular} from "../src/Modular.sol";

contract DeployModularScript is Script {
    function run() external returns (Modular modularContract) {
        address modularManager = 0x3A3Bcb3b225d0e672C6066389207F3DcAF9aF49F; // zup multisig

        vm.startBroadcast();
        modularContract = new Modular{salt: keccak256("modular")}(modularManager);
        vm.stopBroadcast();
    }
}
