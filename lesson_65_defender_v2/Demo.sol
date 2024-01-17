// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error NotAnOwner();

contract Demo {
    address public owner;

    uint public lastDepositAt;
    uint private constant DELAY = 120;
    mapping(address => uint) balances;

    event Deposited(uint indexed amount, address sender);

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotAnOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value > 0, "wrong sum!");

        lastDepositAt = block.timestamp;
        balances[msg.sender] += msg.value;

        emit Deposited(msg.value, msg.sender);
    }

    function withdraw() external {
        uint balance = balances[msg.sender];
        require(balance > 0, "nothing was deposited!");

        balances[msg.sender] = 0;
        
        payable(msg.sender).transfer(balance);
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {
        deposit();
    }
}