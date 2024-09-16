// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC6909ContentURI} from "./IERC6909ContentURI.sol";

contract ERC6909ContentURI is IERC6909ContentURI {
    // Mapping to store URIs for each token ID
    mapping(uint256 => string) private _tokenURIs;

    // Variable to store the contract-level URI
    string private _contractURI;

    // Constructor to set the initial contract-level URI (optional)
    constructor(string memory initialContractURI) {
        _contractURI = initialContractURI;
    }

    // Returns the contract-level URI
    function contractURI() external view returns (string memory uri) {
        return _contractURI;
    }

    // Returns the token-level URI for a specific token ID
    function tokenURI(uint256 id) external view returns (string memory uri) {
        return _tokenURIs[id];
    }

    function _setContractURI(string memory newContractURI) internal {
        _contractURI = newContractURI;
    }

    function _setTokenURI(uint256 id, string memory uri_) internal {
        _tokenURIs[id] = uri_;
    }
}
