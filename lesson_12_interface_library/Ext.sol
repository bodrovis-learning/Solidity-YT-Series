// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library StrExt {
    function eq(string memory str1, string memory str2) internal pure returns(bool) {
        return keccak256(abi.encode(str1)) == keccak256(abi.encode(str2));
    }
}

library ArrayExt {
    function inArray(uint[] memory arr, uint el) internal pure returns(bool) {
        for(uint i = 0; i < arr.length; i++) {
            if(arr[i] == el) {
                return true;
            }
        }

        return false;
    }
}