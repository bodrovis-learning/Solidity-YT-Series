// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {BaconV1, IBaconV1} from "../src/BaconV1.sol";
import {BaconV2, IBaconV2} from "../src/BaconV2.sol";
import {MyBaconProxy} from "../src/MyBaconProxy.sol";
import {MyEggProxy} from "../src/MyEggProxy.sol";
import {MyBeacon} from "../src/MyBeacon.sol";

contract BeaconTest is Test {
    BaconV1 baconV1;
    MyBeacon beacon;
    address baconProxy;
    address eggProxy;

    address alice = makeAddr("alice");

    function setUp() external {
        baconV1 = new BaconV1();
        beacon = new MyBeacon(address(baconV1), alice);

        baconProxy = address(new MyBaconProxy(address(beacon)));
        eggProxy = address(new MyEggProxy(address(beacon)));
    }

    function test_implementation() external view {
        assertEq(beacon.implementation(), address(baconV1));
    }

    function test_v1() external {
        populateAndTestV1Data();
    }

    function populateAndTestV1Data() private {
        IBaconV1 proxiedBaconV1 = IBaconV1(baconProxy);

        proxiedBaconV1.addToA(3);

        assertEq(proxiedBaconV1.getA(), 3);

        IBaconV1 proxiedEggV1 = IBaconV1(eggProxy);

        proxiedEggV1.addToA(12);

        assertEq(proxiedEggV1.getA(), 12);

        assertEq(proxiedBaconV1.getA(), 3);
    }

    function test_upgrade() external {
        BaconV2 baconV2 = new BaconV2();

        populateAndTestV1Data();

        vm.prank(alice);
        beacon.upgradeTo(address(baconV2));

        IBaconV2 proxiedBaconV2 = IBaconV2(baconProxy);

        proxiedBaconV2.multiplyA();

        assertEq(proxiedBaconV2.getA(), 6);

        IBaconV2 proxiedEggV2 = IBaconV2(eggProxy);

        proxiedEggV2.multiplyA();

        assertEq(proxiedEggV2.getA(), 24);
    }
}
