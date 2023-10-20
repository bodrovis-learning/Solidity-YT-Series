// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/KrukToken.sol";
import "../src/FlashBorrower.sol";
import {IERC3156FlashLender} from "../src/IERC3156FlashLender.sol";

contract KrukTokenTest is Test {
    KrukToken ktk;
    FlashBorrower borrower;
    address self = address(this);
    event Action1(address borrower, address token, uint amount, uint fee);

    function setUp() public {
        ktk = new KrukToken();
        borrower = new FlashBorrower(IERC3156FlashLender(address(ktk)));

        ktk.mint(address(borrower), 10);
    }

    function testFlashBorrow() public {
        assertEq(ktk.balanceOf(self), 0);
        uint amount = 20000;
        uint fee = ktk.flashFee(address(ktk), amount);

        vm.expectEmit(false, false, false, true, address(borrower));
        emit Action1(address(borrower), address(ktk), amount, fee);
        borrower.flashBorrow(address(ktk), amount, abi.encode(1));

        assertEq(ktk.balanceOf(self), fee);
    }
}