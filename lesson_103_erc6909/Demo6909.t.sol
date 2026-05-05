// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Demo6909} from "../src/Demo6909.sol";

contract Demo6909Test is Test {
    Demo6909 token;

    uint256 constant TLTK = 1;
    uint256 constant SILVER = 2;
    uint256 constant TICKET = 3;
    uint256 constant LP_CLAIM = 100;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address spender = makeAddr("spender");

    function setUp() public {
        token = new Demo6909(owner);
    }

    function testInitialMetadataAndSupply() public view {
        assertEq(token.name(TLTK), "Tolkien Token");
        assertEq(token.symbol(TLTK), "TLTK");
        assertEq(token.decimals(TLTK), 18);

        assertEq(token.name(TICKET), "Lecture Ticket");
        assertEq(token.decimals(TICKET), 0);

        assertEq(token.totalSupply(TLTK), 1_000_000e18);
        assertEq(token.totalSupply(SILVER), 1_000_000_000 * 10 ** 6);
        assertEq(token.totalSupply(TICKET), 1_000);
        assertEq(token.totalSupply(LP_CLAIM), 10_000e18);
    }

    function testClaimDemoPack() public {
        vm.prank(alice);
        token.claimDemoPack();

        assertEq(token.balanceOf(alice, TLTK), 100e18);
        assertEq(token.balanceOf(alice, SILVER), 500 * 10 ** 6);
        assertEq(token.balanceOf(alice, TICKET), 1);

        assertEq(token.totalSupply(TLTK), 1_000_100e18);
        assertEq(token.totalSupply(TICKET), 1_001);
    }

    function testCannotClaimTwice() public {
        vm.startPrank(alice);

        token.claimDemoPack();

        vm.expectRevert(Demo6909.AlreadyClaimed.selector);
        token.claimDemoPack();

        vm.stopPrank();
    }

    function testTransferSingleTokenId() public {
        vm.prank(alice);
        token.claimDemoPack();

        vm.prank(alice);
        token.transfer(bob, TLTK, 25e18);

        assertEq(token.balanceOf(alice, TLTK), 75e18);
        assertEq(token.balanceOf(bob, TLTK), 25e18);

        // Other token ids are untouched.
        assertEq(token.balanceOf(alice, SILVER), 500 * 10 ** 6);
        assertEq(token.balanceOf(bob, SILVER), 0);
    }

    function testPerIdApproval() public {
        vm.prank(alice);
        token.claimDemoPack();

        // Alice approves spender only for TLTK.
        vm.prank(alice);
        token.approve(spender, TLTK, 10e18);

        assertEq(token.allowance(alice, spender, TLTK), 10e18);
        assertEq(token.allowance(alice, spender, SILVER), 0);

        // Spender can move TLTK.
        vm.prank(spender);
        token.transferFrom(alice, bob, TLTK, 7e18);

        assertEq(token.balanceOf(bob, TLTK), 7e18);
        assertEq(token.allowance(alice, spender, TLTK), 3e18);

        // But spender cannot move SILVER, because approval was only for TLTK.
        vm.prank(spender);
        vm.expectRevert();
        token.transferFrom(alice, bob, SILVER, 1);
    }

    function testGlobalOperator() public {
        vm.prank(alice);
        token.claimDemoPack();

        // Operator is global: spender can move all ids owned by Alice.
        vm.prank(alice);
        token.setOperator(spender, true);

        assertTrue(token.isOperator(alice, spender));

        vm.prank(spender);
        token.transferFrom(alice, bob, SILVER, 100 * 10 ** 6);

        vm.prank(spender);
        token.transferFrom(alice, bob, TICKET, 1);

        assertEq(token.balanceOf(bob, SILVER), 100 * 10 ** 6);
        assertEq(token.balanceOf(bob, TICKET), 1);
    }

    function testBurnOwnTokens() public {
        vm.prank(alice);
        token.claimDemoPack();

        vm.prank(alice);
        token.burn(TICKET, 1);

        assertEq(token.balanceOf(alice, TICKET), 0);
        assertEq(token.totalSupply(TICKET), 1_000);
    }

    function testBurnFromWithPerIdApproval() public {
        vm.prank(alice);
        token.claimDemoPack();

        vm.prank(alice);
        token.approve(spender, TLTK, 20e18);

        vm.prank(spender);
        token.burnFrom(alice, TLTK, 15e18);

        assertEq(token.balanceOf(alice, TLTK), 85e18);
        assertEq(token.allowance(alice, spender, TLTK), 5e18);
        assertEq(token.totalSupply(TLTK), 1_000_085e18);
    }

    function testOwnerMintOnlyKnownIds() public {
        vm.prank(owner);
        token.ownerMint(bob, LP_CLAIM, 123e18);

        assertEq(token.balanceOf(bob, LP_CLAIM), 123e18);

        vm.expectRevert(abi.encodeWithSelector(Demo6909.UnknownTokenId.selector, 999));

        vm.prank(owner);
        token.ownerMint(bob, 999, 1);
    }
}
