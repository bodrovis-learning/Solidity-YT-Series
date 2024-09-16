// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC6909Metadata {
    // Returns the name of the contract associated with a token ID.
    function name(uint256 id) external view returns (string memory name);

    // Returns the symbol of the contract associated with a token ID.
    function symbol(uint256 id) external view returns (string memory symbol);

    // Returns the number of decimals used for a token ID.
    function decimals(uint256 id) external view returns (uint8 amount);
}
