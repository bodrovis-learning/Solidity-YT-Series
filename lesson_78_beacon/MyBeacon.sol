// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {UpgradeableBeacon} from "@openzeppelin/proxy/beacon/UpgradeableBeacon.sol";

contract MyBeacon is UpgradeableBeacon {
    constructor(address implementation_, address initialOwner) UpgradeableBeacon(implementation_, initialOwner) {}
}
