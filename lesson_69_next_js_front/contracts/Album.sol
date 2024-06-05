// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AlbumTracker.sol";

contract Album {
    uint256 public price;
    string public title;
    bool public purchased;
    uint256 public index;
    AlbumTracker tracker;

    constructor(uint256 _price, string memory _title, uint256 _index, AlbumTracker _tracker) {
        price = _price;
        title = _title;
        index = _index;
        tracker = _tracker;
    }

    receive() external payable {
        require(purchased == false, "This album is already purchased!");
        require(price == msg.value, "We accept only full payments!");

        (bool success,) =
            address(tracker).call{value: msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
        require(success, "Sorry, we could not process your transaction.");

        purchased = true;
    }
}
