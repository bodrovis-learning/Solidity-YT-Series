// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BeaconProxy} from "@openzeppelin/proxy/beacon/BeaconProxy.sol";

contract MyEggProxy is BeaconProxy {
    constructor(address beacon) BeaconProxy(beacon, "") {}
}
