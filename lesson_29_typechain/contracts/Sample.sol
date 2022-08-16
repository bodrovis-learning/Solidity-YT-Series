//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sample {
    uint demo = 42;
    string public message;
    address public caller;

    function get() public view returns(uint) {
        return demo;
    }

    function pay(string memory _message) public payable {
        demo = msg.value;
        message = _message;
    }

    function callError() public pure {
        assert(false); // Panic
    }

    function callMe() public {
        caller = msg.sender;
    }
}