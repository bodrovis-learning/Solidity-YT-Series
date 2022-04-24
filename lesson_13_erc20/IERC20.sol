// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function decimals() external pure returns(uint); // 0

    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address to, uint amount) external;

    function allowance(address _owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external;

    function transferFrom(address sender, address recipient, uint amount) external;

    event Transfer(address indexed from, address indexed to, uint amount);

    event Approve(address indexed owner, address indexed to, uint amount);
}