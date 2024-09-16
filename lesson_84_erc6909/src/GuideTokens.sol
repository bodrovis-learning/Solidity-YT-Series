// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC6909} from "./ERC6909.sol";
import {ERC6909TokenSupply} from "./ERC6909TokenSupply.sol";
import {ERC6909Metadata} from "./ERC6909Metadata.sol";
import {ERC6909ContentURI} from "./ERC6909ContentURI.sol";

contract GuideTokens is ERC6909, ERC6909TokenSupply, ERC6909Metadata, ERC6909ContentURI {
    error NotAnOwner(address caller);

    address private _owner;
    uint256 private _nextTokenId;

    modifier onlyOwner() {
        require(msg.sender == _owner, NotAnOwner(msg.sender));

        _;
    }

    constructor(address owner, string memory _initialContractURI) ERC6909ContentURI(_initialContractURI) {
        _owner = owner;

        uint256 tokenId0 = _nextTokenId++;
        _mint(_owner, tokenId0, 5 * 10 ** 18);
        _setTokenMetadata(tokenId0, "Token Zero", "TK0", 18);
        _setTokenURI(tokenId0, "http://example.com/tokens/gtk/0.json");

        uint256 tokenId1 = _nextTokenId++;
        _mint(_owner, tokenId1, 5 * 10 ** 18);
        _setTokenMetadata(tokenId1, "Token One", "TK1", 18);
        _setTokenURI(tokenId1, "http://example.com/tokens/gtk/1.json");
    }

    function mint(address receiver, uint256 id, uint256 amount) public onlyOwner {
        _mint(receiver, id, amount);
    }

    function burn(address sender, uint256 id, uint256 amount) public {
        _burn(sender, id, amount);
    }

    function _mint(address receiver, uint256 id, uint256 amount) internal override(ERC6909, ERC6909TokenSupply) {
        super._mint(receiver, id, amount);
    }

    function _burn(address sender, uint256 id, uint256 amount) internal override(ERC6909, ERC6909TokenSupply) {
        super._burn(sender, id, amount);
    }
}
