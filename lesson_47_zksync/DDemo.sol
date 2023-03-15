//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract DDemo {
    uint private secret;

    constructor(uint _secret) {
        secret = _secret;
    }

    function getSecret() external view returns (uint) {
        return secret;
    }

    function setSecret(uint _newSecret) public {
        secret = _newSecret;
    }
}
