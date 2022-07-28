//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";
import "hardhat/console.sol";

contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Strings for uint;

    string private _name;
    string private _symbol;

    mapping(address => uint) private _balances;
    mapping(uint => address) private _owners;
    mapping(uint => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    modifier _requireMinted(uint tokenId) {
        require(_exists(tokenId), "not minted!");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function transferFrom(address from, address to, uint tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not approved or owner!");

        _transfer(from, to, tokenId);
    }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint tokenId
    // ) public {
    //     safeTransferFrom(from, to, tokenId, "");
    // }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not owner!");
        _safeTransfer(from, to, tokenId, data);
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns(uint) {
        require(owner != address(0), "owner cannot be zero");

        return _balances[owner];
    }

    function ownerOf(uint tokenId) public view _requireMinted(tokenId) returns(address) {
        return _owners[tokenId];
    }

    function approve(address to, uint tokenId) public {
        address _owner = ownerOf(tokenId);

        require(
            _owner == msg.sender || isApprovedForAll(_owner, msg.sender),
            "not an owner!"
        );

        require(to != _owner, "cannot approve to self");

        _tokenApprovals[tokenId] = to;

        emit Approval(_owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "cannot approve to self");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint tokenId) public view _requireMinted(tokenId) returns(address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);

        require(_checkOnERC721Received(address(0), to, tokenId, data), "non-erc721 receiver");
    }

    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "zero address to");
        require(!_exists(tokenId), "this token id is already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _owners[tokenId] = to;
        _balances[to]++;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not owner!");

        _burn(tokenId);
    }

    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        delete _tokenApprovals[tokenId];
        _balances[owner]--;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _baseURI() internal pure virtual returns(string memory) {
        return "";
    }

    function tokenURI(uint tokenId) public view virtual _requireMinted(tokenId) returns(string memory) {

        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ?
            string(abi.encodePacked(baseURI, tokenId.toString())) :
            "";
    }

    function _exists(uint tokenId) internal view returns(bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint tokenId) internal view returns(bool) {
        address owner = ownerOf(tokenId);

        return(
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender
        );
    }

    function _safeTransfer(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);

        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "transfer to non-erc721 receiver"
        );
    }
    
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) private returns(bool) {
        if(to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch(bytes memory reason) {
                if(reason.length == 0) {
                    revert("Transfer to non-erc721 receiver");
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
    
    function _transfer(address from, address to, uint tokenId) internal {
        require(ownerOf(tokenId) == from, "incorrect owner!");
        require(to != address(0), "to address is zero!");

        _beforeTokenTransfer(from, to, tokenId);

        delete _tokenApprovals[tokenId];

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from, address to, uint tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from, address to, uint tokenId
    ) internal virtual {}
}