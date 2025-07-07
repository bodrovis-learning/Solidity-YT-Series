// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC1271} from "./IERC1271.sol";

/// @title MySmartWallet
/// @notice A minimal ERC‑1271 smart wallet implementation verifying ECDSA signatures
contract MySmartWallet is IERC1271 {
    // Immutable owner address set at deployment
    address public immutable owner;

    /// @dev Magic value per ERC‑1271
    bytes4 private constant MAGICVALUE = 0x1626ba7e;
    bytes4 private constant INVALID = 0xffffffff;

    /// @param _owner The address authorized to sign messages
    constructor(address _owner) {
        require(_owner != address(0), "Owner cannot be zero address");
        owner = _owner;
    }

    /// @notice Validates a signature for given hash
    /// @param hash      The message hash that was signed
    /// @param signature The ECDSA signature (r, s, v)
    /// @return magicValue 0x1626ba7e if valid, otherwise 0xffffffff
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4 magicValue)
    {
        // Recover signer and compare to owner
        if (_recover(hash, signature) == owner) {
            return MAGICVALUE;
        }
        return INVALID;
    }

    /// @dev Recovers the signer address from a hash and signature
    /// @param hash      The message hash that was signed
    /// @param signature The ECDSA signature (r, s, v)
    /// @return signer The address that signed the given hash
    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address signer) {
        // Signature must be 65 bytes (r,s,v)
        require(signature.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract r, s, v from signature
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // EIP-2: ensure s-value is in lower half order and v in {27,28}
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid s value");
        require(v == 27 || v == 28, "Invalid v value");

        // Perform ecrecover
        signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Invalid signature");
    }
}
