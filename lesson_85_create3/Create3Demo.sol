//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Create3.sol";

contract Child {
    uint256 meaningOfLife;
    address owner;

    constructor(uint256 _meaning, address _owner) {
        meaningOfLife = _meaning;
        owner = _owner;
    }
}

event Deployed(address indexed target);

contract Deployer {
    function predictAddr(bytes memory _salt) external view returns (address) {
        return Create3.addressOf(keccak256(_salt));
    }

    function deployChild(bytes memory _salt) external {
        address _to =
            Create3.create3(keccak256(_salt), abi.encodePacked(type(Child).creationCode, abi.encode(42, msg.sender)));
        emit Deployed(_to);
    }
}
