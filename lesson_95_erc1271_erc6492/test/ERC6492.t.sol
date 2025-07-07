// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MySmartWallet} from "../src/MySmartWallet.sol";
import {WalletFactory} from "../src/WalletFactory.sol";
import {Validator6492} from "../src/Validator6492.sol";

contract Test6492 is Test {
    WalletFactory public factory;
    Validator6492 public validator;
    address public owner;
    uint256 public ownerPK;
    bytes32 public salt;

    function setUp() public {
        factory = new WalletFactory();
        validator = new Validator6492();
        ownerPK = 1;
        owner = vm.addr(ownerPK);
        salt = keccak256("some-salt");
    }

    function testValidateCounterfactualSignature() public {
        address predicted = factory.computeAddress(owner, salt);

        bytes32 hash = keccak256(abi.encodePacked("login with counterfactual wallet"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPK, hash);
        bytes memory sig = abi.encodePacked(r, s, v);

        bytes memory factoryCalldata = abi.encodeWithSelector(factory.deployWallet.selector, owner, salt);

        // [factory address || factoryCalldata || signature]
        bytes memory prefix = abi.encode(address(factory), factoryCalldata, sig);
        bytes memory wrappedSig = abi.encodePacked(prefix, validator.ERC6492_MAGIC_BYTES());

        bool valid = validator.validateSignature(predicted, hash, wrappedSig);
        assertTrue(valid, "Counterfactual signature should be valid");
    }

    function testInvalidSignatureFails() public {
        address predicted = factory.computeAddress(owner, salt);

        bytes32 hash = keccak256(abi.encodePacked("login with counterfactual wallet"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, hash);
        bytes memory sig = abi.encodePacked(r, s, v);

        bytes memory factoryCalldata = abi.encodeWithSelector(factory.deployWallet.selector, owner, salt);

        bytes memory prefix = abi.encode(address(factory), factoryCalldata, sig);
        bytes memory wrappedSig = abi.encodePacked(prefix, validator.ERC6492_MAGIC_BYTES());

        bool valid = validator.validateSignature(predicted, hash, wrappedSig);
        assertFalse(valid, "Invalid signature should fail");
    }
}
