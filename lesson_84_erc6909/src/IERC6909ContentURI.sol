// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC6909ContentURI {
    // Returns the URI for the contract metadata.
    function contractURI() external view returns (string memory uri);

    // Returns the URI for the specific token ID.
    // May revert if the token ID does not exist.
    function tokenURI(uint256 id) external view returns (string memory uri);
}
