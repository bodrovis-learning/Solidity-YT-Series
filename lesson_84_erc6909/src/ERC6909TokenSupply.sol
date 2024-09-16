// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC6909TokenSupply} from "./IERC6909TokenSupply.sol";
import {ERC6909} from "./ERC6909.sol";

contract ERC6909TokenSupply is IERC6909TokenSupply, ERC6909 {
    // Mapping to store the total supply for each token ID
    mapping(uint256 => uint256) private _totalSupply;

    // Returns the total supply for a given token ID
    function totalSupply(uint256 id) external view returns (uint256 supply) {
        return _totalSupply[id];
    }

    // Override the internal mint function to update the total supply
    function _mint(address receiver, uint256 id, uint256 amount) internal virtual override {
        _totalSupply[id] += amount;
        super._mint(receiver, id, amount);
    }

    // Override the internal burn function to update the total supply
    function _burn(address sender, uint256 id, uint256 amount) internal virtual override {
        require(_totalSupply[id] >= amount, "Insufficient total supply");

        _totalSupply[id] -= amount;

        super._burn(sender, id, amount);
    }
}
