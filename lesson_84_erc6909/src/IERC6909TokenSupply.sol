// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC6909TokenSupply {
    // Returns the total supply for a given token ID.
    function totalSupply(uint256 id) external view returns (uint256 supply);
}
