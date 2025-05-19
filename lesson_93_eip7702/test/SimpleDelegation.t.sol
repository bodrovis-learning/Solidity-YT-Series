// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {SimpleDelegation, SecondSC} from "../src/SimpleDelegation.sol";

contract SimpleDelegationTest is Test {
    uint256 alicePK;
    address aliceAddr;

    uint256 bobPK;
    address bobAddr;

    SimpleDelegation delegation;
    SecondSC secondSC;

    function setUp() public {
        delegation = new SimpleDelegation();
        (aliceAddr, alicePK) = makeAddrAndKey("alice");
        (bobAddr, bobPK) = makeAddrAndKey("bob");
        secondSC = new SecondSC();

        vm.deal(aliceAddr, 20 ether);
        vm.deal(bobAddr, 20 ether);
    }

    function testDelegate() external {
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(
            address(delegation),
            alicePK
        );

        vm.startBroadcast(bobPK);

        vm.attachDelegation(signedDelegation);

        // SimpleDelegation(aliceAddr).callMe(address(secondSC));
        // (bool success,) = aliceAddr.call{value: 10 ether}("");
        // require(success);
        payable(aliceAddr).transfer(10 ether);


        console.log(aliceAddr.balance);
        console.log(bobAddr.balance);
    }
}
