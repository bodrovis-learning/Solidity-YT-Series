// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MySmartWallet} from "./MySmartWallet.sol";

/// @title WalletFactory
/// @notice Deploys MySmartWallet instances via CREATE2 and computes their addresses off-chain
contract WalletFactory {
    /// @notice Emitted when a new wallet is deployed
    /// @param walletAddress The address of the deployed wallet
    event WalletDeployed(address indexed walletAddress);

    /// @notice Deploys a MySmartWallet for `owner` using CREATE2 with `salt`
    /// @param owner The owner address to assign in the new wallet
    /// @param salt A salt to make the CREATE2 address unique
    /// @return walletAddress The address where the wallet was deployed
    function deployWallet(address owner, bytes32 salt) external returns (address walletAddress) {
        require(owner != address(0), "WalletFactory: owner is zero address");

        walletAddress = address(new MySmartWallet{salt: salt}(owner));
        emit WalletDeployed(walletAddress);
    }

    /// @notice Computes the CREATE2 address for a wallet deployed with `owner` and `salt`
    /// @param owner The owner address to be used in deployment
    /// @param salt The same salt that will be used in deployWallet
    /// @return predicted The address where the wallet *would* be deployed
    function computeAddress(address owner, bytes32 salt) external view returns (address predicted) {
        bytes memory bytecode = abi.encodePacked(type(MySmartWallet).creationCode, abi.encode(owner));

        predicted = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)))))
        );
    }
}
