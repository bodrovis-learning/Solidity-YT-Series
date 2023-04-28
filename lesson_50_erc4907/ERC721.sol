// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./ERC165.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";

contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint => address) private _owners;
    mapping(address => uint) private _balances;
    mapping(uint => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0));

        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "tokenID is invalid");
        return owner;
    }

    function name() external view virtual returns(string memory) {
        return _name;
    }

    function symbol() external view virtual returns(string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI(); // ipfs:// https://example.com/nfts/
        // ipfs:// + tokenId
        // ipfs://123def12312dabc
        return bytes(baseURI).length > 0 ?
            // .concat
            string(abi.encodePacked(baseURI, tokenId.toString())) :
            "";
    }

    function _baseURI() internal view virtual returns(string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) external virtual {
        address owner = ownerOf(tokenId);
        require(to != owner);

        require(
            msg.sender == owner ||
            isApprovedForAll(owner, msg.sender)
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) external virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);

        require(_checkOnERC721Received(from, to, tokenId, data));
    }

    function _ownerOf(uint tokenId) internal view virtual returns(address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns(bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns(bool) {
        address owner = ownerOf(tokenId);

        return(
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender
        );
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);

        require(_checkOnERC721Received(address(0), to, tokenId, data));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0));

        require(!_exists(tokenId));

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        require(!_exists(tokenId));

        unchecked {
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from);

        require(to != address(0));

        _beforeTokenTransfer(from, to, tokenId, 1);

        require(ownerOf(tokenId) == from);

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator);
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId));
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns(bool) {
        if(to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch(bytes memory reason) {
                if(reason.length == 0) {
                    revert("Non-erc721 receiver!");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint, uint batchSize) internal virtual {
        if(batchSize > 1) {
            if(from != address(0)) {
                _balances[from] -= batchSize;
            }

            if(to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    function _afterTokenTransfer(address from, address to, uint tokenId, uint batchSize) internal virtual {}
}