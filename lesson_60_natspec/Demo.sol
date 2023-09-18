// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error NotAnOwner(address caller);

/// @title Demo SC for YouTube
/// @author Kruk
/// @notice A simple wallet (demo)
/// @dev Dev-specific info
contract Demo {
    /// @notice The current owner of this SC
    /// @dev Cannot be address(0)
    /// @return The owner
    address public owner;
    uint public lastDepositAt;
    uint public constant DELAY = 120;

    /// @notice Emitted when funds are received
    /// @param amount Deposited amount
    /// @param sender The actual sender
    event Deposited(uint indexed amount, address indexed sender);

    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotAnOwner(msg.sender);
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Deposit funds to the wallet
    function deposit() public payable {
        require(msg.value > 0, "nothing has been deposited!");

        lastDepositAt = block.timestamp;

        emit Deposited(msg.value, msg.sender);
    }

    /// @notice Withdraw funds from the wallet
    /// @param _amount The amount to widthdraw
    function withdraw(uint _amount) external onlyOwner {
        require(block.timestamp > lastDepositAt + DELAY, "too early!");

        payable(msg.sender).transfer(_amount);
    }
    
    /// @notice Do some calculations
    /// @param _a Value 1
    /// @param _b Value 2
    /// @return The result of calculations
    function calculate(uint _a, uint _b) external returns(uint) {
        // ...
    }

    /// 
    /// @param _c The input param
    /// @custom:sample The sample tag
    function secretFunc(uint _c) internal {
        // ...
    }

    receive() external payable {
        deposit();
    }
}