// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {GuideTokens} from "../src/GuideTokens.sol";

contract GuideTokensTest is Test {
    GuideTokens gtk;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() external {
        gtk = new GuideTokens(alice, "http://example.com/tokens/gtk.json");
    }

    function test_init() external view {
        assertEq(gtk.contractURI(), "http://example.com/tokens/gtk.json");
        assertEq(gtk.tokenURI(0), "http://example.com/tokens/gtk/0.json");
        assertEq(gtk.tokenURI(1), "http://example.com/tokens/gtk/1.json");

        assertEq(gtk.name(0), "Token Zero");
        assertEq(gtk.symbol(0), "TK0");

        assertEq(gtk.decimals(0), 18);

        assertEq(gtk.balanceOf(alice, 0), withDecimals(0, 5));
        assertEq(gtk.totalSupply(0), withDecimals(0, 5));
    }

    function test_mint() external {
        uint256 tokenId = 0;
        uint256 amountToMint = withDecimals(tokenId, 2);
        uint256 oldSupply = gtk.totalSupply(tokenId);

        vm.prank(alice);

        gtk.mint(bob, tokenId, amountToMint);

        assertEq(gtk.balanceOf(bob, tokenId), amountToMint);
        assertEq(gtk.totalSupply(tokenId), oldSupply + amountToMint);
    }

    function test_burn() external {
        uint256 tokenId = 1;
        uint256 amountToBurn = withDecimals(tokenId, 2);
        uint256 oldSupply = gtk.totalSupply(tokenId);

        vm.prank(alice);
        gtk.setOperator(bob, true);

        vm.prank(bob);
        gtk.burn(alice, tokenId, amountToBurn);

        assertEq(gtk.balanceOf(alice, tokenId), oldSupply - amountToBurn);
        assertEq(gtk.totalSupply(tokenId), oldSupply - amountToBurn);
    }

    function test_transfer() external {
        uint256 tokenId = 1;
        uint256 amountToTransfer = withDecimals(tokenId, 2);
        uint256 tokenSupply = gtk.totalSupply(tokenId);

        vm.prank(alice);
        gtk.transfer(bob, tokenId, amountToTransfer);

        assertEq(gtk.balanceOf(alice, tokenId), tokenSupply - amountToTransfer);
        assertEq(gtk.balanceOf(bob, tokenId), amountToTransfer);

        assertEq(gtk.totalSupply(tokenId), tokenSupply);
    }

    function test_transferFrom() external {
        uint256 tokenId = 1;
        uint256 tokenSupply = gtk.totalSupply(tokenId);
        uint256 amountToTransfer = tokenSupply;

        vm.prank(alice);
        gtk.approve(bob, tokenId, type(uint256).max);

        vm.prank(bob);
        gtk.transferFrom(alice, bob, tokenId, amountToTransfer);

        assertEq(gtk.balanceOf(bob, tokenId), amountToTransfer);
        assertEq(gtk.balanceOf(alice, tokenId), 0);
    }

    function withDecimals(uint256 tokenId, uint256 baseAmount) private view returns (uint256) {
        uint8 decimals = gtk.decimals(tokenId);

        return baseAmount * 10 ** decimals;
    }
}
