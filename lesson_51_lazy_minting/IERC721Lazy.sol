// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Lazy {
    function redeem(
        address owner,
        address redeemer,
        uint tokenId,
        uint minPrice,
        string memory uri,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns(bytes32);
}