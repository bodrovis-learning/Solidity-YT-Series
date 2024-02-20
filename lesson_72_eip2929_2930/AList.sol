// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AList {

    function callOther(address _toCall, uint _a) external {
        (bool ok,) = _toCall.call(
            abi.encodeWithSelector(Target.callMe.selector, _a)
        );
        require(ok);
    }
}

contract Target {
    uint a; // 0

    function callMe(uint _a) external {
        a = _a;
    }
}