// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint assets,
        uint shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint assets,
        uint shares
    );

    function asset() external view returns(address assetTokenAddress);

    function totalAssets() external view returns(uint totalManagedAssets);

    function convertToShares(uint assets) external view returns(uint shares);

    function convertToAssets(uint shares) external view returns(uint assets);

    function maxDeposit(address receiver) external view returns(uint maxAssets);

    function previewDeposit(uint assets) external view returns(uint shares);

    // кладёт указанное количество токенов, создаёт n-ное кол-во долей
    function deposit(uint assets, address receiver) external returns(uint shares);

    function maxMint(address receiver) external view returns(uint maxShares);

    function previewMint(uint shares) external view returns(uint assets);

    // создаёт указанное кол-во долей, высчитывает сколько токенов нужно взять
    // у юзера, который ф-цию вызвал
    function mint(uint shares, address receiver) external returns(uint assets);

    function maxWithdraw(address owner) external view returns(uint maxAssets);

    function previewWithdraw(uint assets) external view returns(uint shares);

    // возвращает указанное кол-во токенов, сжигает соотв. кол-во долей
    function withdraw(uint assets, address receiver, address owner) external returns(uint shares);
    
    function maxRedeem(address owner) external view returns(uint maxShares);

    function previewRedeem(uint shares) external view returns(uint assets);

    // сжигает ровно указанное кол-во долей, возвращает некоторое кол-во токенов
    // в соответствии с этими долями
    function redeem(uint shares, address receiver, address owner) external returns(uint assets);
}