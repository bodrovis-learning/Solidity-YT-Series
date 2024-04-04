// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Vault, Attacker, Oracle} from "../src/ReentrReadOnly.sol";

contract ReentrancyReadOnlyTest is Test {
    Vault private vault;
    Attacker private attacker;
    Oracle private oracle;
    address alice = makeAddr("alice");

    function setUp() external {
        vault = new Vault();
        oracle = new Oracle(address(vault));
        attacker = new Attacker(address(vault), address(oracle));

        vm.deal(address(attacker), attacker.DEPOSIT_AMOUNT());
    }

    function testAttack() public {
        hoax(alice);
        vault.deposit{value: 5 ether}();

        attacker.attack();

        assertEq(attacker.priceBefore(), 2);
        assertEq(attacker.priceAfter(), 2);
        assertEq(attacker.priceDuring(), 7);
    }
}
