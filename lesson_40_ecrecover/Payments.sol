// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Payments {
    address public owner;

    mapping(uint => bool) nonces;

    constructor() payable {
        require(msg.value > 0);
        owner = msg.sender;
    }

    function claim(uint256 amount, uint256 nonce, bytes memory signature) external {
        require(!nonces[nonce], "nonce already used!");

        nonces[nonce] = true;

        bytes32 message = withPrefix(keccak256(abi.encodePacked(
            msg.sender,
            amount,
            nonce,
            address(this)
        )));

        require(
            recoverSigner(message, signature) == owner, "invalid sig!"
        );

        payable(msg.sender).transfer(amount);
    }

    function recoverSigner(bytes32 message, bytes memory signature) private pure returns(address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory signature) private pure returns(uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65);

        assembly {
            r := mload(add(signature, 32))

            s := mload(add(signature, 64))

            v := byte(0, mload(add(signature, 96)))
        }

        return(v, r, s);
    }

    function withPrefix(bytes32 _hash) private pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                _hash
            )
        );
    }
}