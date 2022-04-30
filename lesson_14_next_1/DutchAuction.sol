// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'hardhat/console.sol';

contract DutchAuction {
    uint private constant DURATION = 2 days;
    address payable public immutable seller;
    uint public immutable startingPrice;
    uint public immutable startAt;
    uint public immutable endsAt;
    uint public immutable discountRate;
    string public item;
    bool public stopped;

    event Bought(uint price, address buyer);

    constructor(uint _startingPrice, uint _discountRate, string memory _item) {
        require(_startingPrice >= _discountRate * DURATION, "price too low!");
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        endsAt = block.timestamp + DURATION;
        item = _item;
    }

    modifier notStopped {
        require(!stopped, "has already stopped!");
        _;
    }

    function getPrice() public view notStopped returns(uint) {
        uint timeElapsed = block.timestamp - startAt;        
        uint discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function nextBlock() external {

    }

    function buy() external payable notStopped {
        require(block.timestamp < endsAt, "too late!");
        uint price = getPrice();
        require(msg.value >= price, "too low!");
        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
        seller.transfer(address(this).balance);
        stopped = true;
        emit Bought(price, msg.sender);
    }
}