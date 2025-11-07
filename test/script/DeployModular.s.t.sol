// SPDX-License-Identifier: GNU GPLv3
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {DeployModularScript, Modular} from "../../script/DeployModular.s.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DeployModularTest is Test {
    DeployModularScript internal sut;

    function setUp() external {
        sut = new DeployModularScript();
    }

    function test_deploy_assignZupMultisigAsManager() external {
        Modular modularContract = Modular(sut.run());

        assert(Ownable(modularContract).owner() == 0x3A3Bcb3b225d0e672C6066389207F3DcAF9aF49F);
    }
}
