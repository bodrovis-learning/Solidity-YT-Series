// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";

contract ERC20 is IERC20Metadata {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory initialName, string memory symbol_) {
        _name = initialName; // GuideDaoToken
        _symbol = symbol_; // GDT
    }

    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function decimals() public pure virtual returns(uint8) {
        return 0;//18
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender; // != tx.origin

        _transfer(owner, to, amount);

        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        address owner = msg.sender;

        _approve(owner, spender, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = msg.sender;

        _spendAllowance(from, spender, amount);
        
        _transfer(from, to, amount);
        
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public virtual returns(bool) {
        address owner = msg.sender;

        _approve(owner, spender, allowance(owner, spender) + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint subValue) public virtual returns(bool) {
        address owner = msg.sender;

        uint currentAllowance = allowance(owner, spender);

        require(currentAllowance >= subValue, "allowance should be >= subValue");

        unchecked {
            _approve(owner, spender, currentAllowance - subValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint amount) internal virtual {
        require(from != address(0), "From cannot be zero addr!");
        require(to != address(0), "To cannot be zero addr!");

        _beforeTokenTransfer(from, to, amount);

        uint fromBalance = _balances[from];
        require(fromBalance >= amount, "insufficient funds!");

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "Account cannot be zero!");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;

        unchecked {
            _balances[account] += amount;
        }

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "Account cannot be zero!");

        _beforeTokenTransfer(account, address(0), amount);
        
        uint accountBalance = _balances[account];
        require(accountBalance >= amount, "insufficient funds");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "Owner cannot be zero!");
        require(spender != address(0), "Spender cannot be zero!");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint amount) internal virtual {
        uint currentAllowance = allowance(owner, spender);

        if(currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "insufficient allowance");

            unchecked {
                //_allowances[owner][spender] = _allowances[owner][spender] - amount;
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint amount) internal virtual {}
}

// contract GuideDaoToken is ERC20 {

// }