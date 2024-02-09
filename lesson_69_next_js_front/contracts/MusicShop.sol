//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "hardhat/console.sol";

contract MusicShop is ERC165 {
    struct Album {
        uint256 index;
        bytes32 uid;
        string title;
        uint256 price;
        uint256 quantity;
    }

    struct Order {
        uint256 orderId;
        bytes32 albumUid;
        address customer;
        uint256 orderedAt;
        OrderStatus status;
    }

    enum OrderStatus {
        Paid,
        Delivered
    }

    Album[] public albums;
    Order[] public orders;

    uint256 public currentIndex;
    uint256 public currentOrderId;

    address public owner;

    event AlbumBought(bytes32 indexed uid, address indexed customer, uint256 indexed timestamp);
    event OrderDelivered(bytes32 indexed albumUid, address indexed customer);

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function addAlbum(bytes32 uid, string calldata title, uint256 price, uint256 quantity) external onlyOwner {
        albums.push(
            Album({
                index: currentIndex,
                uid: uid,
                title: title,
                price: price,
                quantity: quantity
            })
        );

        currentIndex++;
    }

    function buy(uint256 _index) external payable {
        Album storage albumToBuy = albums[_index];

        require(msg.value == albumToBuy.price, "invalid price");
        require(albumToBuy.quantity > 0, "out of stock!");

        albumToBuy.quantity--;

        orders.push(
            Order({
                orderId: currentOrderId,
                albumUid: albumToBuy.uid,
                customer: msg.sender,
                orderedAt: block.timestamp,
                status: OrderStatus.Paid
            })
        );

        currentOrderId++;

        emit AlbumBought(albumToBuy.uid, msg.sender, block.timestamp);
    }

    function delivered(uint256 _index) external onlyOwner {
        Order storage currentOrder = orders[_index];

        require(currentOrder.status != OrderStatus.Delivered, "invalid status");

        currentOrder.status = OrderStatus.Delivered;

        emit OrderDelivered(currentOrder.albumUid, currentOrder.customer);
    }

    receive() external payable {
        revert("Please use the buy function to purchase albums!");
    }

    function allAlbums() external view returns (Album[] memory) {
        uint totalAlbums = albums.length;
        Album[] memory albumsList = new Album[](totalAlbums);

        for (uint256 i = 0; i < totalAlbums; ++i) {
            albumsList[i] = albums[i];
        }

        return albumsList;
    }

    fallback() external {
        console.logBytes(msg.data);
    }
}
