// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Demo} from "../src/Demo.sol";
import {DemoAuthority} from "../src/DemoAuthority.sol";

error AccessManagedUnauthorized(address caller);
error AccessManagerNotScheduled(bytes32 operationId);

event OperationCanceled(bytes32 indexed operationId, uint32 indexed nonce);

contract DemoTest is Test {
    Demo demo;
    DemoAuthority authority;
    address self = address(this);
    address alice = makeAddr("alice");
    uint64 constant DELAYED_ADMIN_ROLE = 1;

    function setUp() external {
        authority = new DemoAuthority(self);
        demo = new Demo(address(authority));
    }

    function test_nonSecret() external {
        vm.prank(alice);

        demo.nonSecret();

        assertTrue(demo.nonSecretCalled());
    }

    function test_secret() external {
        demo.secret();

        assertTrue(demo.secretCalled());
    }

    function test_secretRevert() external {
        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSelector(AccessManagedUnauthorized.selector, alice));

        demo.secret();
    }

    function test_secretWithGranted() external {
        authority.grantRole(authority.ADMIN_ROLE(), alice, 0);

        vm.prank(alice);

        demo.secret();

        assertTrue(demo.secretCalled());
    }

    function test_delayedReverted() external {
        uint32 requiredDelay = 5;

        bytes4[] memory selectors = new bytes4[](1);

        authority.grantRole(DELAYED_ADMIN_ROLE, alice, requiredDelay);

        (bool isMember, uint32 executionDelay) = authority.hasRole(DELAYED_ADMIN_ROLE, alice);

        assertTrue(isMember);
        assertEq(executionDelay, requiredDelay);

        selectors[0] = Demo.delayed.selector;

        authority.setTargetFunctionRole(address(demo), selectors, DELAYED_ADMIN_ROLE);

        bytes32 hashedOp = authority.hashOperation(alice, address(demo), abi.encodePacked(Demo.delayed.selector));

        vm.prank(alice);

        vm.expectRevert(abi.encodeWithSelector(AccessManagerNotScheduled.selector, hashedOp));
        demo.delayed();
    }

    function test_delayedWithGrantedAndScheduled() external {
        uint32 requiredDelay = 5;

        bytes4[] memory selectors = new bytes4[](1);

        authority.grantRole(DELAYED_ADMIN_ROLE, alice, requiredDelay);

        selectors[0] = Demo.delayed.selector;

        authority.setTargetFunctionRole(address(demo), selectors, DELAYED_ADMIN_ROLE);

        bytes memory _calldata = abi.encodePacked(Demo.delayed.selector);

        vm.prank(alice);

        (bytes32 opId, uint32 nonce) = authority.schedule(address(demo), _calldata, 0);

        bytes32 hashedOp = authority.hashOperation(alice, address(demo), _calldata);

        assertEq(nonce, 1);
        assertEq(opId, hashedOp);

        uint48 delay = authority.getSchedule(opId);
        assertEq(delay, requiredDelay + 1);

        skip(delay);

        vm.prank(alice);
        demo.delayed();

        assertTrue(demo.delayedCalled());
    }

    function test_delayedCancel() external {
        uint32 requiredDelay = 10;

        bytes4[] memory selectors = new bytes4[](1);

        authority.grantRole(DELAYED_ADMIN_ROLE, alice, requiredDelay);

        selectors[0] = Demo.delayed.selector;

        authority.setTargetFunctionRole(address(demo), selectors, DELAYED_ADMIN_ROLE);

        bytes memory _calldata = abi.encodePacked(Demo.delayed.selector);

        vm.prank(alice);

        (bytes32 opId, uint32 nonce) = authority.schedule(address(demo), _calldata, 0);

        vm.expectEmit(true, true, false, false);
        emit OperationCanceled(opId, nonce);

        uint32 cancelNonce = authority.cancel(alice, address(demo), _calldata);

        assertEq(cancelNonce, nonce);

        uint48 delay = authority.getSchedule(opId);

        skip(delay);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(AccessManagerNotScheduled.selector, opId));
        demo.delayed();
    }
}
