// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface ITarget {
    function ping() external payable;
}

contract SimpleLogic {
    event Forwarded(address target, address sender, address origin, uint256 value);

    function doSomething(address target) external payable {
        ITarget(target).ping{value: msg.value}();
        emit Forwarded(target, msg.sender, tx.origin, msg.value);
    }
}

contract PingTarget is ITarget {
    event Pinged(address sender, address origin, uint256 value, bool delegated);

    function ping() external payable {
        bool isDelegated;

        assembly {
            // We'll load the first 32 bytes of code from msg.sender
            let ptr := mload(0x40)
            extcodecopy(caller(), ptr, 0, 32)
            let prefix := shr(232, mload(ptr)) // grab first 3 bytes (24 bits)

            // Check if prefix == 0xef0100
            isDelegated := eq(prefix, 0xef0100)
        }

        emit Pinged(msg.sender, tx.origin, msg.value, isDelegated);
    }
}
