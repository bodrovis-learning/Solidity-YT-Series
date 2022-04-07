// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Balances is Ownable {
    function getBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function withdraw(address payable _to) public override virtual onlyOwner {
        _to.transfer(getBalance());
    }
}

contract MyContract is Ownable, Balances {
    constructor(address _owner) {
        owner = _owner;
    }

    function withdraw(address payable _to) public override(Ownable, Balances) onlyOwner {
        //Balances.withdraw(_to);
        //Ownable.withdraw(_to);
        require(_to != address(0), "zero addr");
        super.withdraw(_to);
    }
}