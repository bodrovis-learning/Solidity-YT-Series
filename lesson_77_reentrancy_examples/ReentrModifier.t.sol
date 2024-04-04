// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import {DemoToken, BonusAttack} from "../src/ReentrModifier.sol";

// contract ReentrancyModifierTest is Test {
//     DemoToken token;
//     BonusAttack attacker;
//     uint256 constant RECEIVE_TIMES = 10;

//     function setUp() public {
//         token = new DemoToken();
//         attacker = new BonusAttack(address(token), RECEIVE_TIMES);
//     }

//     function test_attack() external {
//         attacker.attack();

//         assertEq(attacker.receivedCount(), RECEIVE_TIMES);
//         assertEq(token.balances(address(attacker)), token.BONUS_AMOUNT() * RECEIVE_TIMES);
//     }
// }
