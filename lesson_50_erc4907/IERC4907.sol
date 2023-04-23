// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC4907 {
    event UpdateUser(uint indexed tokenId, address indexed user, uint64 expires);

    function setUser(uint tokenId, address user, uint64 expires) external;

    function userOf(uint tokenId) external view returns(address);

    function userExpires(uint tokenId) external view returns(uint);
}
