// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Album.sol";

contract AlbumTracker is Ownable {
    enum AlbumState {
        Created,
        Paid,
        Delivered
    }

    struct AlbumProduct {
        Album album;
        AlbumState state;
        uint256 price;
        string title;
    }

    event AlbumStateChanged(address indexed _albumAddress, uint256 _albumIndex, uint256 _stateNum);

    mapping(uint256 => AlbumProduct) public albums;
    uint256 public currentIndex;

    constructor() Ownable(msg.sender) {}

    function createAlbum(uint256 _price, string memory _title) public {
        Album newAlbum = new Album(_price, _title, currentIndex, this);

        albums[currentIndex].album = newAlbum;
        albums[currentIndex].state = AlbumState.Created;
        albums[currentIndex].price = _price;
        albums[currentIndex].title = _title;

        emit AlbumStateChanged(address(newAlbum), currentIndex, uint256(albums[currentIndex].state));

        currentIndex++;
    }

    function triggerPayment(uint256 _index) public payable {
        require(albums[_index].state == AlbumState.Created, "This album is already purchased!");
        require(albums[_index].price == msg.value, "We accept only full payments!");

        albums[_index].state = AlbumState.Paid;

        emit AlbumStateChanged(address(albums[_index].album), _index, uint256(albums[_index].state));
    }

    function triggerDelivery(uint256 _index) public onlyOwner {
        require(albums[_index].state == AlbumState.Paid, "This album is not paid for!");

        albums[_index].state = AlbumState.Delivered;

        emit AlbumStateChanged(address(albums[_index].album), _index, uint256(albums[_index].state));
    }
}
