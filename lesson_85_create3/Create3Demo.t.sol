// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Deployer, Deployed} from "../src/Create3Demo.sol";

contract DemoTest is Test {
    Deployer deployer;

    function setUp() external {
        deployer = new Deployer();
    }

    function test_predictAddr() external view {
        console.log(deployer.predictAddr(bytes("demo salt")));
    }

    function test_deploy() external {
        address predictedAddr = deployer.predictAddr(bytes("demo salt"));

        vm.expectEmit(true, false, false, false);
        emit Deployed(predictedAddr);

        deployer.deployChild(bytes("demo salt1"));
    }
}