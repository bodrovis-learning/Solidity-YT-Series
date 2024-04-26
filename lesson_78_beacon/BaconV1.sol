// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IBaconV1 {
    function addToA(uint256 _add) external;

    function getA() external view returns (uint256);
}

contract BaconV1 is IBaconV1 {
    uint256 a;

    function addToA(uint256 _add) external {
        a += _add;
    }

    function getA() public view returns (uint256) {
        return a;
    }
}
