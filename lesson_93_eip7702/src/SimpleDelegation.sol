// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract SimpleDelegation {
    event Called(address origin, address sender, uint value);
    bool called;

    function getCalled() external view returns(bool) {
        return called;
    }
 
    function callMe(address _target) external payable {
        called = true;
        SecondSC(_target).secondFunc{value: 10 ether}();
        emit Called(tx.origin, msg.sender, msg.value);
    }

    // receive() external payable {}
}

contract SecondSC {
    event SecondCalled(address origin, address sender, uint value);

    function secondFunc() external payable {
        emit SecondCalled(tx.origin, msg.sender, msg.value);
    }
}