// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Storage is Ownable {
    uint myVal;

    constructor(address initialOwner) payable Ownable(initialOwner) {}

    event Stored(uint newVal);

    function store(uint _newVal) external onlyOwner {
        myVal = _newVal;
        emit Stored(myVal);
    }

    function sendMoney(address _to, uint _amount) external {
        (bool ok,) = _to.call{value: _amount}("");
        require(ok, "can't send money");
    }

    function read() external view returns(uint) {
        return myVal;
    }
}