// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ext.sol";

contract LibDemo {
    using StrExt for string;
    using ArrayExt for uint[];

    function runnerArr(uint[] memory numbers, uint number) public pure returns(bool) {
        return numbers.inArray(number);
    }

    function runnerStr(string memory str1, string memory str2) public pure returns(bool) {
        return str1.eq(str2);
    }
}