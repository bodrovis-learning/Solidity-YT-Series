// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC6551BytecodeLib {
    function getCreationCode(address _impl) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                _impl,
                hex"5af43d82803e903d91602b57fd5bf3"
            );
    }
}

contract Maker {
    address public lastDeployedAddr;

    event Created(address target);

    function make(address _impl) external {
        bytes memory code = ERC6551BytecodeLib.getCreationCode(_impl);

        address target;

        assembly {
            target := create(0, add(code, 0x20), mload(code))
        }

        emit Created(target);

        lastDeployedAddr = target;
    }
}

contract Impl {
    uint public a;

    function callMe(uint _a) external {
        a = _a;
    }
}