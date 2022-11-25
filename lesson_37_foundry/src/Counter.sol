// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error NotAnOwner();

contract Counter {
    uint public myNum;
    address public owner;

    event Inc(uint indexed number, address indexed initiator);

    modifier onlyOwner() {
        //require(msg.sender == owner, "not an owner!");
        if(msg.sender != owner) {
            revert NotAnOwner();
        }
        _;
    }

    constructor(uint _initialNum) {
        myNum = _initialNum;
        owner = msg.sender;
    }

    function increment() external onlyOwner {
        myNum++;

        emit Inc(myNum, msg.sender);
    }

    receive() external payable {}
}