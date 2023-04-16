// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC4626.sol";
import "./utils/Math.sol";

abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _underlyingDecimals;

    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    function _tryGetAssetDecimals(IERC20 asset_) private view returns(bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if(success && encodedDecimals.length >= 32) {
            uint returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if(returnedDecimals <= type(uint8).max) {
                return(true, uint8(returnedDecimals));
            }
        }
        return(false, 0);
    }

    function asset() public view virtual returns(address) {
        return address(_asset);
    }

    function totalAssets() public view virtual returns(uint) {
        return _asset.balanceOf(address(this));
    }

    function convertToShares(uint assets) public view virtual returns(uint) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    function convertToAssets(uint shares) public view virtual returns(uint) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    function maxDeposit(address) public view virtual returns(uint) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns(uint) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns(uint) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    function maxRedeem(address owner) public view virtual returns(uint) {
        return balanceOf(owner);
    }

    function previewDeposit(uint assets) public view virtual returns(uint) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    function previewMint(uint shares) public view virtual returns(uint) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    function previewWithdraw(uint assets) public view virtual returns(uint) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    function previewRedeem(uint shares) public view virtual returns(uint) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    function deposit(uint assets, address receiver) public virtual returns(uint) {
        require(assets <= maxDeposit(receiver));

        uint shares = previewDeposit(assets);

        _deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    function mint(uint shares, address receiver) public virtual returns(uint) {
        require(shares <= maxMint(receiver));

        uint assets = previewMint(shares);

        _deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    function withdraw(
        uint assets,
        address receiver,
        address owner
    ) public virtual returns(uint) {
        require(assets <= maxWithdraw(owner));

        uint shares = previewWithdraw(assets);

        _withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    function redeem(
        uint shares,
        address receiver,
        address owner
    ) public virtual returns(uint) {
        require(shares <= maxRedeem(owner));

        uint assets = previewRedeem(shares);

        _withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    function _deposit(
        address caller,
        address receiver,
        uint assets,
        uint shares
    ) internal virtual {
        _asset.transferFrom(caller, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint assets,
        uint shares
    ) internal virtual {
        if(caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);

        _asset.transfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _convertToShares(
        uint assets,
        Math.Rounding rounding
    ) internal view virtual returns(uint) {
        // (assets * totalSupply) / totalAssets
        return assets.mulDiv(
            totalSupply() + 10 ** _decimalOffset(),
            totalAssets() + 1,
            rounding
        );
    }

    function _convertToAssets(
        uint shares,
        Math.Rounding rounding
    ) internal view virtual returns(uint) {
        return shares.mulDiv(
            totalAssets() + 1,
            totalSupply() + 10 ** _decimalOffset(),
            rounding
        );
    }

    function _decimalOffset() internal view virtual returns(uint8) {
        return 0;
    }
}