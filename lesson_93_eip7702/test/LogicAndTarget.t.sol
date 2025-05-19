// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/LogicAndTarget.sol";

contract SimpleDelegationTest is Test {
    // Actors
    uint256 alicePK;
    address payable aliceAddr;

    uint256 bobPK;
    address bobAddr;

    // Contracts
    SimpleLogic public logic;
    PingTarget public target;

    function setUp() public {
        // Generate key pairs
        address temp;
        (temp, alicePK) = makeAddrAndKey("ALICE");
        aliceAddr = payable(temp);
        (bobAddr, bobPK) = makeAddrAndKey("BOB");

        // Fund both
        vm.deal(aliceAddr, 10 ether);
        vm.deal(bobAddr, 10 ether);

        // Deploy logic and target contracts
        logic = new SimpleLogic();
        target = new PingTarget();
    }

    /// ------------------------------------------------------------------------
    /// ✅ Baseline test: EOA is empty by default
    /// ------------------------------------------------------------------------
    function testAliceHasNoCodeInitially() public view {
        assertEq(aliceAddr.code.length, 0, "Alice should not have code initially");
    }

    /// ------------------------------------------------------------------------
    /// ✅ Confirm delegation writes code to the EOA
    /// ------------------------------------------------------------------------
    function testDelegationAttachesCodeToEOA() public {
        // Sanity: no code before
        assertEq(aliceAddr.code.length, 0, "should start with no code");

        Vm.SignedDelegation memory signed = vm.signDelegation(address(logic), alicePK);

        vm.startBroadcast(alicePK);
        vm.attachDelegation(signed);
        vm.stopBroadcast();

        assertGt(aliceAddr.code.length, 0, "Alice should have delegation code");
        bytes memory code = aliceAddr.code;
        assertEq(code[0], hex"ef");
        assertEq(code[1], hex"01");
        assertEq(code[2], hex"00");
    }

    /// ------------------------------------------------------------------------
    /// ✅ Alice delegates + calls through her own logic
    /// ------------------------------------------------------------------------
    function testAliceSelfExecutesViaDelegation() public {
        Vm.SignedDelegation memory signed = vm.signDelegation(address(logic), alicePK);

        vm.startBroadcast(alicePK);
        vm.attachDelegation(signed);

        // Call into her own logic (as Alice)
        SimpleLogic(aliceAddr).doSomething(address(target));
        vm.stopBroadcast();
    }

    /// ------------------------------------------------------------------------
    /// ✅ Bob sends tx that triggers delegated Alice logic
    /// ------------------------------------------------------------------------
    function testBobExecutesViaDelegatedAlice() public {
        Vm.SignedDelegation memory signed = vm.signDelegation(address(logic), alicePK);

        vm.startBroadcast(bobPK);
        vm.attachDelegation(signed);
        SimpleLogic(aliceAddr).doSomething(address(target));
        vm.stopBroadcast();
    }

    /// ------------------------------------------------------------------------
    /// ❌ Attempting to call EOA before delegation should revert (no code)
    /// ------------------------------------------------------------------------
    function testCallFailsWithoutDelegation() public {
        // Alice has no code yet
        assertEq(aliceAddr.code.length, 0, "Alice must not have code yet");

        // Trying to cast her address as a contract and call it = revert
        vm.startBroadcast(bobPK);

        vm.expectRevert(); // or omit
        (bool ok,) = address(aliceAddr).call(abi.encodeWithSelector(SimpleLogic.doSomething.selector, address(target)));
        require(!ok, "Expected call to fail");
        vm.stopBroadcast();
    }
}
