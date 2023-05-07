// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./crypto/ECDSA.sol";
import "./crypto/EIP712.sol";
import "./ERC721URIStorage.sol";

abstract contract ERC721Lazy is ERC721URIStorage, EIP712 {
    mapping(address => uint) pendingWithdrawals;

    bytes32 private constant _VOUCHER_TYPEHASH = keccak256(
        "NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)"
    );

    constructor(string memory name) EIP712(name, "1") {}

    function redeem(
        address owner,
        address redeemer,
        uint tokenId,
        uint minPrice,
        string memory uri,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable returns(uint) {
        require(msg.value >= minPrice);

        bytes32 structHash = keccak256(
            abi.encode(
                _VOUCHER_TYPEHASH,
                tokenId,
                minPrice,
                keccak256(bytes(uri))
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == owner);

        _mint(signer, tokenId);
        _setTokenURI(tokenId, uri);

        _transfer(signer, redeemer, tokenId);

        pendingWithdrawals[signer] += msg.value;

        return tokenId;
    }

    function withdraw() public {
        address receiver = msg.sender;

        uint amount = availableToWithdraw(receiver);
        require(amount > 0);

        pendingWithdrawals[receiver] = 0;
        
        (bool ok,) = receiver.call{value: amount}("");

        require(ok);
    }

    function availableToWithdraw(address receiver) public view returns (uint) {
        return pendingWithdrawals[receiver];
    }

    function DOMAIN_SEPARATOR() external view returns(bytes32) {
        return _domainSeparatorV4();
    }
}