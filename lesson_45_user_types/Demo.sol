//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// block.difficulty --> deprecated
// prevrandao

// selfdestruct --> deprecated

// a: UFixed256x3 = 3
// a * 10 ^ 3
// b = 5
// b * 10 ^ 3
type UFixed256x3 is uint256;

function add(UFixed256x3 a, UFixed256x3 b) pure returns(UFixed256x3) {
    return UFixed256x3.wrap(
        UFixed256x3.unwrap(a) + UFixed256x3.unwrap(b)
    );
}

function eq(UFixed256x3 a, UFixed256x3 b) pure returns(bool) {
    return UFixed256x3.unwrap(a) == UFixed256x3.unwrap(b);
}
// library Math {
//     function add(UFixed256x3 a, UFixed256x3 b) public pure returns(UFixed256x3) {
//         return UFixed256x3.wrap(
//             UFixed256x3.unwrap(a) + UFixed256x3.unwrap(b)
//         );
//     }
// }

using { add as +, eq as ==, eq } for UFixed256x3 global;

contract Demo {
    // using { Math.add } for UFixed256x3;

    // function mul(UFixed256x3 val, uint k) external pure returns(UFixed256x3) {
    //     return UFixed256x3.wrap(
    //         UFixed256x3.unwrap(val) * k
    //     );
    // }

    function run(UFixed256x3 val1, UFixed256x3 val2) external pure returns(UFixed256x3) {
        // return val1.add(val2);
        val1 == val2;
        val1.eq(val2);
        return val1 + val2;
    }
}