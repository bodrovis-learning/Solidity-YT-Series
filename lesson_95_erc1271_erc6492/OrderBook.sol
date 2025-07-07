// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC1271} from "./IERC1271.sol";

/// @title OrderBook
/// @notice A simple contract to accept off-chain orders signed by smart wallets via ERC-1271
contract OrderBook {
    /// @dev Magic value returned by ERC-1271 for a valid signature
    bytes4 private constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

    /// @notice Submit an off-chain order for on-chain processing
    /// @param wallet The address of the ERC-1271 compliant smart wallet
    /// @param hash The bytes32 hash of the order data that was signed
    /// @param signature The signature bytes to validate
    /// @return valid True if the smart wallet recognizes the signature as valid
    function submitOrder(address wallet, bytes32 hash, bytes calldata signature) external view returns (bool valid) {
        require(wallet != address(0), "OrderBook: wallet address is zero");

        // Call isValidSignature on the wallet and compare to magic value
        bytes4 result = IERC1271(wallet).isValidSignature(hash, signature);
        return (result == ERC1271_MAGIC_VALUE);
    }
}
