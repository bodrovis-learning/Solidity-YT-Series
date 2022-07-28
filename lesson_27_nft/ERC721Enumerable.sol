//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    uint[] private _allTokens;
    mapping(address => mapping(uint => uint)) private _ownedTokens;
    mapping(uint => uint) private _allTokensIndex;
    mapping(uint => uint) private _ownedTokensIndex;

    function totalSupply() public view returns(uint) {
        return _allTokens.length;
    }

    function tokenByIndex(uint index) public view returns(uint) {
        require(index < totalSupply(), "out of bonds");

        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint index) public view returns(uint) {
        require(index < balanceOf(owner), "out of bonds");

        return _ownedTokens[owner][index];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns(bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if(from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if(from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if(to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if(to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToAllTokensEnumeration(uint tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromAllTokensEnumeration(uint tokenId) private {
        uint lastTokenIndex = _allTokens.length - 1;
        uint tokenIndex = _allTokensIndex[tokenId];

        uint lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function _addTokenToOwnerEnumeration(address to, uint tokenId) private {
        uint _length = balanceOf(to);

        _ownedTokensIndex[tokenId] = _length;
        _ownedTokens[to][_length] = tokenId;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint tokenId) private {
        uint lastTokenIndex = balanceOf(from) - 1;
        uint tokenIndex = _ownedTokensIndex[tokenId];

        if(tokenIndex != lastTokenIndex) {
            uint lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}