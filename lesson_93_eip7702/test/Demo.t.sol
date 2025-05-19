// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {SimpleDelegateContract, ERC20} from "../src/Demo.sol";

contract SignDelegationTest is Test {
    // ---------------------------------------------------------------------
    // Keys & addresses (generated on the fly, no hard-coding)
    // ---------------------------------------------------------------------
    uint256 private alicePK;
    address payable private aliceAddr;

    uint256 private bobPK;
    address private bobAddr;

    // Contracts
    SimpleDelegateContract public implementation;
    ERC20 public token;

    // ---------------------------------------------------------------------
    // Setup
    // ---------------------------------------------------------------------
    function setUp() public {
        // Deterministic key-pair generation (stdCheats)
        address aliceAddrTemp;
        (aliceAddrTemp, alicePK) = makeAddrAndKey("ALICE");
        aliceAddr = payable(aliceAddrTemp);
        (bobAddr, bobPK) = makeAddrAndKey("BOB");

        // Give both some ETH so they can transact
        vm.deal(aliceAddr, 10 ether);
        vm.deal(bobAddr, 10 ether);

        // Deploy delegation target and ERC-20 token
        implementation = new SimpleDelegateContract();
        token = new ERC20(aliceAddr); // Alice is the minter
    }

    function testSignDelegationAndThenAttachDelegation() public {
        // Construct a single transaction call: Mint 100 tokens to Bob.
        SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        bytes memory data = abi.encodeCall(ERC20.mint, (100, bobAddr));
        calls[0] = SimpleDelegateContract.Call({to: address(token), data: data, value: 0});

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), alicePK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.broadcast(bobPK);
        vm.attachDelegation(signedDelegation);

        // Verify that Alice's account now behaves as a smart contract.
        bytes memory code = address(aliceAddr).code;
        require(code.length > 0, "no code written to Alice");

        // As Bob, execute the transaction via Alice's assigned contract.
        SimpleDelegateContract(aliceAddr).execute(calls);

        // Verify Bob successfully received 100 tokens.
        assertEq(token.balanceOf(bobAddr), 100);
    }

    function testSignAndAttachDelegation() public {
        // Construct a single transaction call: Mint 100 tokens to Bob.
        SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        bytes memory data = abi.encodeCall(ERC20.mint, (100, bobAddr));
        calls[0] = SimpleDelegateContract.Call({to: address(token), data: data, value: 0});

        // Alice signs and attaches the delegation in one step (eliminating the need for separate signing).
        vm.signAndAttachDelegation(address(implementation), alicePK);

        // Verify that Alice's account now behaves as a smart contract.
        bytes memory code = address(aliceAddr).code;
        require(code.length > 0, "no code written to Alice");

        // As Bob, execute the transaction via Alice's assigned contract.
        vm.broadcast(bobPK);
        SimpleDelegateContract(aliceAddr).execute(calls);

        // Verify Bob successfully received 100 tokens.
        vm.assertEq(token.balanceOf(bobAddr), 100);
    }
}
