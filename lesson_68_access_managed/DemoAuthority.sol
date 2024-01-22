// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./AccessManager.sol";

contract DemoAuthority is AccessManager {
    constructor(address initialAdmin) AccessManager(initialAdmin) {}
}
