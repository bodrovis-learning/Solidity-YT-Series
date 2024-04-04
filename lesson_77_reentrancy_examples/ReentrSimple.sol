// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    mapping(address owner => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public noReentrancy {
        uint256 balance = balances[msg.sender];

        balances[msg.sender] = 0;

        (bool result,) = msg.sender.call{value: balance}("");
        require(result, "cannot withdraw funds");
    }
}

contract Attacker {
    Vault public vault;

    constructor(address _vault) payable {
        vault = Vault(_vault);
        vault.deposit{value: msg.value}();
    }

    function attack() external payable {
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            vault.withdraw();
        }
    }
}
