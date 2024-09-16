// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC6909 {
    // Event emitted when a token transfer occurs.
    event Transfer(
        address indexed caller, address indexed sender, address indexed receiver, uint256 id, uint256 amount
    );

    // Event emitted when an operator is set or revoked.
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    // Event emitted when approval is granted.
    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);

    // Returns the total balance of token `id` held by `owner`.
    function balanceOf(address owner, uint256 id) external view returns (uint256 amount);

    // Returns the remaining number of token `id` that `spender` is allowed to spend on behalf of `owner`.
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 amount);

    // Returns true if `spender` is approved as an operator for `owner`.
    function isOperator(address owner, address spender) external view returns (bool status);

    /// @notice Transfers an amount of an id from the caller to a receiver.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool success);

    /// @notice Transfers an amount of an id from a sender to a receiver.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount)
        external
        returns (bool success);

    /// @notice Approves an amount of an id to a spender.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function approve(address spender, uint256 id, uint256 amount) external returns (bool success);

    /// @notice Sets or removes a spender as an operator for the caller.
    /// @param spender The address of the spender.
    /// @param approved The approval status.
    function setOperator(address spender, bool approved) external returns (bool success);
}
