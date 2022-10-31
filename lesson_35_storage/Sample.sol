// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Sample {
    uint256 a = 123; // 0
    uint[] arr; // 1 --> main (length)
    // keccak256(1) 0x...

    mapping(address => uint) mapp; // 2 --> main (length)
    // keccak256(k CONCAT p)
    constructor() {
        arr.push(10);
        arr.push(20);
        mapp[address(this)] = 100;
    }
}