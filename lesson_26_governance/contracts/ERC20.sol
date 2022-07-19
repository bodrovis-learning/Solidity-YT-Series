// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint totalTokens;
    address owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    string _name;
    string _symbol;

    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "not enough tokens!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint initialSupply
    ) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        mint(initialSupply, owner);
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint) {
        return 18;
    }

    function totalSupply() public view returns(uint) {
        return totalTokens;
    }

    function balanceOf(address account) public view returns(uint) {
        return balances[account];
    }

    function transfer(address to, uint amount) external enoughTokens(msg.sender, amount) {
        _beforeTokenTransfer(msg.sender, to, amount);

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function allowance(address _owner, address spender) external view returns(uint) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint amount) external {
        allowances[msg.sender][spender] = amount;

        emit Approve(msg.sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external {
        _beforeTokenTransfer(sender, recipient, amount);

        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function mint(uint amount, address _to) public onlyOwner {
        _beforeTokenTransfer(address(0), _to, amount);

        balances[_to] += amount;
        totalTokens += amount;

        emit Transfer(address(0), _to, amount);
    }

    function burn(address _from, uint _amount) public onlyOwner enoughTokens(_from, _amount) {
        _beforeTokenTransfer(_from, address(0), _amount);

        balances[_from] -= _amount;
        totalTokens -= _amount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal virtual {}
}