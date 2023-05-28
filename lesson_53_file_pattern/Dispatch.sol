// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Dispatch {
    bytes32 public secret;
    address public addr;
    uint public a;
    uint public b;

    // event SecretUpdated(bytes32 indexed newSecret);
    // event AddrUpdated(address indexed newAddr);
    // event AUpdated(uint indexed newA);
    // event BUpdated(uint indexed newB);

    error InvalidTarget(bytes32 target);
    event Dispatched(bytes32 target, bytes value);

    function dispatch(bytes32 target, bytes calldata value) external {
        if(target == "secret") secret = abi.decode(value, (bytes32));
        else if (target == "addr") addr = abi.decode(value, (address));
        else if (target == "a") a = abi.decode(value, (uint256));
        else if (target == "b") b = abi.decode(value, (uint256));
        else revert InvalidTarget(target);

        emit Dispatched(target, value);
    }

    function dispatch(bytes32 target, address value) external {
        if (target == "addr") addr = value;
        else revert InvalidTarget(target);

        emit Dispatched(target, abi.encode(value));
    }

    // function updateSecret(bytes32 newSecret) external {
    //     secret = newSecret;
    //     emit SecretUpdated(newSecret);
    // }

    // function updateAddr(address newAddr) external {
    //     addr = newAddr;
    //     emit AddrUpdated(newAddr);
    // }

    // function updateA(uint newA) external {
    //     a = newA;
    //     emit AUpdated(newA);
    // }

    // function updateB(uint newB) external {
    //     b = newB;
    //     emit BUpdated(newB);
    // }
}