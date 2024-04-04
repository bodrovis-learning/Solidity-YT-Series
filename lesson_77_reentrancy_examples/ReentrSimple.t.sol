// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";

// import {Vault, Attacker} from "../src/ReentrSimple.sol";

// contract ReentrancySimpleTest is Test {
//     Attacker attacker;
//     Vault vault;
//     address alice = makeAddr("alice");
//     uint256 constant ALICE_DEPOSIT = 3 ether;
//     uint256 constant HACKER_DEPOSIT = 1 ether;

//     function setUp() public {
//         vault = new Vault();
//         attacker = new Attacker{value: HACKER_DEPOSIT}(address(vault));

//         hoax(alice);
//         vault.deposit{value: ALICE_DEPOSIT}();
//     }

//     function test_attack() external {
//         attacker.attack();
//         assertEq(address(vault).balance, 0);
//         assertEq(address(attacker).balance, HACKER_DEPOSIT + ALICE_DEPOSIT);
//     }
// }
