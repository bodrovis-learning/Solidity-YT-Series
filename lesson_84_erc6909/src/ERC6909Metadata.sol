// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC6909Metadata} from "./IERC6909Metadata.sol";

contract ERC6909Metadata is IERC6909Metadata {
    // Mappings to store metadata for each token ID
    mapping(uint256 => string) private _names;
    mapping(uint256 => string) private _symbols;
    mapping(uint256 => uint8) private _decimals;

    // Returns the name of the contract for a specific token ID
    function name(uint256 id) external view override returns (string memory) {
        return _names[id];
    }

    // Returns the symbol of the contract for a specific token ID
    function symbol(uint256 id) external view override returns (string memory) {
        return _symbols[id];
    }

    // Returns the number of decimals for a specific token ID
    function decimals(uint256 id) external view override returns (uint8) {
        return _decimals[id];
    }

    function _setTokenMetadata(uint256 id, string memory name_, string memory symbol_, uint8 decimals_) internal {
        _names[id] = name_;
        _symbols[id] = symbol_;
        _decimals[id] = decimals_;
    }
}
