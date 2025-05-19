// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {BatchCallAndSponsor} from "../src/BatchCallAndSponsor.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {MessageHashUtils} from "@openzeppelin/utils/cryptography/MessageHashUtils.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract BatchCallAndSponsorTest is Test {
    // Alice's address and private key (EOA with no initial contract code).
    address payable ALICE_ADDRESS;
    uint256 ALICE_PK;

    // Bob's address and private key (Bob will execute transactions on Alice's behalf).
    address BOB_ADDRESS;
    uint256 BOB_PK;

    // The contract that Alice will delegate execution to.
    BatchCallAndSponsor public implementation;

    // ERC-20 token contract for minting test tokens.
    MockERC20 public token;

    event CallExecuted(address indexed to, uint256 value, bytes data);
    event BatchExecuted(uint256 indexed nonce, BatchCallAndSponsor.Call[] calls);

    function setUp() public {
        // Generate key pairs
        address temp;
        (temp, ALICE_PK) = makeAddrAndKey("ALICE");
        ALICE_ADDRESS = payable(temp);
        (BOB_ADDRESS, BOB_PK) = makeAddrAndKey("BOB");

        // Deploy the delegation contract (Alice will delegate calls to this contract).
        implementation = new BatchCallAndSponsor();

        // Deploy an ERC-20 token contract where Alice is the minter.
        token = new MockERC20();

        // Fund accounts
        vm.deal(ALICE_ADDRESS, 10 ether);
        token.mint(ALICE_ADDRESS, 1000e18);
    }

    function testDirectExecution() public {
        console2.log("Sending 1 ETH from Alice to Bob and transferring 100 tokens to Bob in a single transaction");
        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](2);

        // ETH transfer
        calls[0] = BatchCallAndSponsor.Call({to: BOB_ADDRESS, value: 1 ether, data: ""});

        // Token transfer
        calls[1] = BatchCallAndSponsor.Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(ERC20.transfer, (BOB_ADDRESS, 100e18))
        });

        vm.signAndAttachDelegation(address(implementation), ALICE_PK);

        vm.startPrank(ALICE_ADDRESS);
        BatchCallAndSponsor(ALICE_ADDRESS).execute(calls);
        vm.stopPrank();

        assertEq(BOB_ADDRESS.balance, 1 ether);
        assertEq(token.balanceOf(BOB_ADDRESS), 100e18);
    }

    function testSponsoredExecution() public {
        console2.log("Sending 1 ETH from Alice to a random address while the transaction is sponsored by Bob");

        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](1);
        address recipient = makeAddr("recipient");

        calls[0] = BatchCallAndSponsor.Call({to: recipient, value: 1 ether, data: ""});

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(BOB_PK);
        vm.attachDelegation(signedDelegation);

        // Verify that Alice's account now temporarily behaves as a smart contract.
        bytes memory code = address(ALICE_ADDRESS).code;
        require(code.length > 0, "no code written to Alice");
        // console2.log("Code on Alice's account:", vm.toString(code));

        // Debug nonce
        // console2.log("Nonce before sending transaction:", BatchCallAndSponsor(ALICE_ADDRESS).nonce());

        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        bytes32 digest =
            keccak256(abi.encodePacked(BatchCallAndSponsor(ALICE_ADDRESS).nonce(), BOB_ADDRESS, encodedCalls));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        // Expect the event. The first parameter should be BOB_ADDRESS.
        vm.expectEmit(true, true, true, true);
        emit BatchCallAndSponsor.CallExecuted(BOB_ADDRESS, calls[0].to, calls[0].value, calls[0].data);

        // As Bob, execute the transaction via Alice's temporarily assigned contract.
        BatchCallAndSponsor(ALICE_ADDRESS).execute(calls, signature);

        // console2.log("Nonce after sending transaction:", BatchCallAndSponsor(ALICE_ADDRESS).nonce());

        vm.stopBroadcast();

        assertEq(recipient.balance, 1 ether);
    }

    function testSponsoredExecutionByWrongSenderShouldFail() public {
        console2.log("Should fail: Charlie tries to use a sig that Alice intended for Bob only");

        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](1);
        address recipient = makeAddr("recipient");

        calls[0] = BatchCallAndSponsor.Call({to: recipient, value: 1 ether, data: ""});

        // 1️⃣ Alice signs delegation (EIP-7702 style)
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), ALICE_PK);

        // 2️⃣ Attach delegation to Alice’s EOA (anyone can do this part)
        vm.startBroadcast(BOB_PK);
        vm.attachDelegation(signedDelegation);
        vm.stopBroadcast();

        // 3️⃣ Confirm code is now attached to Alice's account
        require(ALICE_ADDRESS.code.length > 0, "no code written to Alice");

        // 4️⃣ Charlie (not Bob) tries to send tx using Bob’s signature
        address CHARLIE_ADDRESS;
        uint256 CHARLIE_PK;
        (CHARLIE_ADDRESS, CHARLIE_PK) = makeAddrAndKey("CHARLIE");

        // 5️⃣ Construct valid signature — signed by Alice for BOB
        bytes memory encodedCalls;
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        uint256 nonce = BatchCallAndSponsor(ALICE_ADDRESS).nonce();
        bytes32 digest = keccak256(abi.encodePacked(nonce, BOB_ADDRESS, encodedCalls));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        // 6️⃣ Expect revert: Charlie uses Bob’s signature
        vm.startBroadcast(CHARLIE_PK);
        vm.expectRevert("Invalid signature");
        BatchCallAndSponsor(ALICE_ADDRESS).execute(calls, signature);
        vm.stopBroadcast();
    }

    function testWrongSignature() public {
        console2.log("Test wrong signature: Execution should revert with 'Invalid signature'.");
        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](1);
        calls[0] = BatchCallAndSponsor.Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(MockERC20.mint, (BOB_ADDRESS, 50))
        });

        // Build the encoded call data.
        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(BOB_PK);
        vm.attachDelegation(signedDelegation);

        bytes32 digest = keccak256(abi.encodePacked(BatchCallAndSponsor(ALICE_ADDRESS).nonce(), encodedCalls));
        // Sign with the wrong key (Bob's instead of Alice's).
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("Invalid signature");
        BatchCallAndSponsor(ALICE_ADDRESS).execute(calls, signature);
        vm.stopBroadcast();
    }

    function testReplayAttack() public {
        console2.log("Test replay attack: Reusing the same signature should revert.");
        BatchCallAndSponsor.Call[] memory calls = new BatchCallAndSponsor.Call[](1);
        calls[0] = BatchCallAndSponsor.Call({
            to: address(token),
            value: 0,
            data: abi.encodeCall(MockERC20.mint, (BOB_ADDRESS, 30))
        });

        // Build encoded call data.
        bytes memory encodedCalls = "";
        for (uint256 i = 0; i < calls.length; i++) {
            encodedCalls = abi.encodePacked(encodedCalls, calls[i].to, calls[i].value, calls[i].data);
        }

        // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(implementation), ALICE_PK);

        // Bob attaches the signed delegation from Alice and broadcasts it.
        vm.startBroadcast(BOB_PK);
        vm.attachDelegation(signedDelegation);

        uint256 nonceBefore = BatchCallAndSponsor(ALICE_ADDRESS).nonce();
        bytes32 digest = keccak256(abi.encodePacked(nonceBefore, BOB_ADDRESS, encodedCalls));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, MessageHashUtils.toEthSignedMessageHash(digest));
        bytes memory signature = abi.encodePacked(r, s, v);

        // First execution: should succeed.
        BatchCallAndSponsor(ALICE_ADDRESS).execute(calls, signature);
        vm.stopBroadcast();

        // Attempt a replay: reusing the same signature should revert because nonce has incremented.
        vm.expectRevert("Invalid signature");
        BatchCallAndSponsor(ALICE_ADDRESS).execute(calls, signature);
    }
}
