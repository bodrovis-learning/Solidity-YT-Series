// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Merkle tree

contract Tree {
    bytes32[] public hashes;
    string[4] transactions = [
        "TX1: Sherlock -> John",
        "TX2: John -> Sherlock",
        "TX3: John -> Mary",
        "TX3: Mary -> Sherlock"
    ];

    constructor() {
        for(uint i = 0; i < transactions.length; i++) {
            hashes.push(makeHash(transactions[i]));
        }

        uint count = transactions.length;
        uint offset = 0;

        while(count > 0) {
            for(uint i = 0; i < count - 1; i += 2) {
                hashes.push(keccak256(
                    abi.encodePacked(
                        hashes[offset + i], hashes[offset + i + 1]
                    )
                ));
            }
            offset += count;
            count = count / 2;
        }
    }

    function verify(string memory transaction, uint index, bytes32 root, bytes32[] memory proof) public pure returns(bool) {
// "TX3: John -> Mary"
// 2
// 0xa0da473a78c18b28d88660e9e845ae6ff6b0cc3e7e6901a4fc8cad162a6aaba8
// 0xdca11aec2d04146b1bbc933b1447aee4927d081c9274fcc6d02809b4ee2e56d8
// 0x58e9a664a4c1e26694e09437cad198aebc6cd3c881ed49daea6e83e79b77fead
//        ROOT

//   H1-2      H3-4

// H1   H2   H3   H4

// TX1  TX2  TX3  TX4
        bytes32 hash = makeHash(transaction);
        for(uint i = 0; i < proof.length; i++) {
            bytes32 element = proof[i];
            if(index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, element));
            } else {
                hash = keccak256(abi.encodePacked(element, hash));
            }
            index = index / 2;
        }
        return hash == root;
    }

    function encode(string memory input) public pure returns(bytes memory) {
        return abi.encodePacked(input);
    }

    function makeHash(string memory input) public pure returns(bytes32) {
        return keccak256(
            encode(input)
        );
    }
}