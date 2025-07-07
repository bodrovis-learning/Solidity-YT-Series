// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC1271} from "./IERC1271.sol";

/// @title Validator6492
/// @notice Validates ERC-1271 signatures for both deployed and counterfactual wallets per ERC-6492
contract Validator6492 {
    /// @dev ERC-6492 magic-bytes suffix to detect wrapped counterfactual signatures
    bytes32 public constant ERC6492_MAGIC_BYTES = 0x6492649264926492649264926492649264926492649264926492649264926492;

    /// @dev ERC-1271 magic value returned by isValidSignature for a valid signature
    bytes4 public constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    /// @notice Validate a signature for a wallet that may not yet be deployed
    /// @param wallet The target wallet address (deployed or counterfactual)
    /// @param hash The digest that was signed
    /// @param signature The signature, optionally wrapped with factory data + magic suffix
    /// @return valid True if the signature is valid according to ERC-1271
    function validateSignature(address wallet, bytes32 hash, bytes calldata signature) external returns (bool valid) {
        require(wallet != address(0), "Validator6492: zero wallet");

        // 1) Detect ERC-6492 wrapper by its magic-bytes suffix
        bool isWrapped;
        bytes32 suffix;
        if (signature.length >= 32) {
            assembly {
                // load last 32 bytes of calldata
                suffix := calldataload(sub(calldatasize(), 32))
            }
            if (suffix == ERC6492_MAGIC_BYTES) {
                isWrapped = true;
            }
        }

        // 2) If wrapped, decode (factory, factoryCalldata, innerSig, suffix)
        bytes memory sig = signature;
        if (isWrapped) {
            (address factoryAddr, bytes memory factoryCalldata, bytes memory innerSig,) =
                abi.decode(signature, (address, bytes, bytes, bytes32));
            sig = innerSig;

            // 3) Deploy counterfactual wallet if not on‐chain yet
            if (wallet.code.length == 0) {
                (bool ok,) = factoryAddr.call(factoryCalldata);
                require(ok, "Validator6492: deploy failed");
            }
        }

        // 4) If wallet is deployed, perform ERC-1271 signature check
        if (wallet.code.length > 0) {
            bytes4 result = IERC1271(wallet).isValidSignature(hash, sig);
            return (result == ERC1271_MAGIC_VALUE);
        }

        // 5) Otherwise the signature is invalid
        return false;
    }
}
