// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IBaconV2 {
    function addToA(uint256 _add) external;

    function getA() external view returns (uint256);

    function multiplyA() external;
}

contract BaconV2 is IBaconV2 {
    uint256 a;

    function addToA(uint256 _add) external {
        a += _add;
    }

    function multiplyA() external {
        a = a * 2;
    }

    function getA() public view returns (uint256) {
        return a;
    }
}
