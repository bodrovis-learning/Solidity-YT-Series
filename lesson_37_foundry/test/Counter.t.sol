// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { Counter, NotAnOwner } from "../src/Counter.sol";
import { Helper } from "./Helper.sol";

contract CounterTest is Test, Helper {
    Counter public counter;

    event Inc(uint indexed number, address indexed initiator);

    function setUp() public {
        counter = new Counter(100);
        //console.log(counter.myNum());
        // console.log(counter.owner());
        // console.log(address(this));
    }

    // function testFailSubstraction() public view {
    //     uint myNum = counter.myNum();
    //     myNum -= 1000;
    // }

    function testSubstractionUnderflow() public {
        uint myNum = counter.myNum();
        vm.expectRevert(stdError.arithmeticError);
        myNum -= 1000;
    }

    function testReceive() public {
        assertEq(address(counter).balance, 0);

        (bool success,) = address(counter).call{value: 100}("");

        assertEq(success, true);
        assertEq(address(counter).balance, 100);
    }

    function testIncrement() public {
        vm.expectEmit(true, true, true, false);
        emit Inc(101, address(this));

        counter.increment();
        assertEq(counter.myNum(), 101);

        // console.log(address(this).balance);
    }

    // function testFailIncrementNotOwner() public {
    //     //vm.prank(address(0));
    //     counter.increment();
    // }

    function testIncrementNotOwner() public {
        vm.expectRevert(NotAnOwner.selector);//(bytes("not an owner!"));
        vm.prank(address(0));
        counter.increment();
    }
}