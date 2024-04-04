// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error NoReentrancy();

abstract contract ReentrancyGuard {
    bool locked;

    modifier noReentrancy() {
        if (locked) {
            revert NoReentrancy();
        }

        locked = true;

        _;

        locked = false;
    }
}
