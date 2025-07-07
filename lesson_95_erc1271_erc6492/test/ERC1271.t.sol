// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MySmartWallet} from "../src/MySmartWallet.sol";
import {OrderBook} from "../src/OrderBook.sol";

contract Test1271 is Test {
    MySmartWallet wallet;
    OrderBook orderBook;
    uint256 privateKey;
    address owner;

    function setUp() public {
        privateKey = 123;
        owner = vm.addr(privateKey);
        wallet = new MySmartWallet(owner);
        orderBook = new OrderBook();
    }

    function testValidSignature() public view {
        bytes32 hash = keccak256(abi.encodePacked("order: buy 10 ETH"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool valid = orderBook.submitOrder(address(wallet), hash, signature);
        assertTrue(valid, "Signature should be valid");
    }

    function testInvalidSignature() public view {
        bytes32 hash = keccak256(abi.encodePacked("order: buy 10 ETH"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, hash);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool valid = orderBook.submitOrder(address(wallet), hash, signature);
        assertFalse(valid, "Signature should be invalid");
    }
}
