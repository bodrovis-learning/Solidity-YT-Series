// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Permit.sol";

contract MyToken is ERC20, ERC20Permit {
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        owner = msg.sender;
        _mint(msg.sender, 100 * 10 ** decimals());
    }

    function mint(address to, uint amount) public onlyOwner {
        _mint(to, amount);
    }
}