// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AccessControl.sol";

contract Demo is AccessControl {
    bool paused;

    bytes32 public constant WITHDRAWER_ROLE = keccak256(bytes("WITHDRAWER_ROLE"));
    bytes32 public constant MINTER_ROLE = keccak256(bytes("MINTER_ROLE"));

    constructor(address _withdrawer) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _grantRole(WITHDRAWER_ROLE, _withdrawer);

        _setRoleAdmin(MINTER_ROLE, WITHDRAWER_ROLE);
    }

    function withdraw() external onlyRole(WITHDRAWER_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = true;
    }
}