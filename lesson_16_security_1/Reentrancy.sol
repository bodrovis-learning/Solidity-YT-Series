// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ReentrancyAuction {
    mapping(address => uint) public bidders;
    bool locked;

    function bid() external payable {
        bidders[msg.sender] += msg.value;
    }

    modifier noReentrancy() {
        require(!locked, "no reentrancy!");
        locked = true;
        _;
        locked = false;
    }
    // pull
    function refund() external noReentrancy {
        uint refundAmount = bidders[msg.sender];

        if (refundAmount > 0) {
            bidders[msg.sender] = 0;

            (bool success,) = msg.sender.call{value: refundAmount}("");

            require(success, "failed!");
        }
    }

    function currentBalance() external view returns(uint) {
        return address(this).balance;
    }
}

contract ReentrancyAttack {
    uint constant BID_AMOUNT = 1 ether;
    ReentrancyAuction auction;

    constructor(address _auction) {
        auction = ReentrancyAuction(_auction);
    }

    function proxyBid() external payable {
        require(msg.value == BID_AMOUNT, "incorrect");
        auction.bid{value: msg.value}();
    }

    function attack() external {
        auction.refund();
    }

    receive() external payable {
        if(auction.currentBalance() >= BID_AMOUNT) {
            auction.refund();
        }
    }

    function currentBalance() external view returns(uint) {
        return address(this).balance;
    }
}