// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

// Взято из frost-secp256k1-evm
import {Memory} from "frost-secp256k1-evm/utils/Memory.sol";
import {Secp256k1} from "frost-secp256k1-evm/utils/cryptography/Secp256k1.sol";
import {Secp256k1Arithmetic} from "frost-secp256k1-evm/utils/cryptography/Secp256k1Arithmetic.sol";
import {Hashes} from "frost-secp256k1-evm/utils/cryptography/Hashes.sol";

/// @title ERC5564Secp256k1
/// @notice Пример имплементации схемы 1 (secp256k1 + view tags) для ERC-5564
contract ERC5564Secp256k1 {
    uint256 internal constant SCHEME_ID = 1;

    // --- публичный API по ERC-5564 ---

    /// @notice Генерирует stealth-адрес из stealth meta-address.
    /// @dev Формат meta-address для этой схемы:
    ///      - длина 33 байта: compressed spend/view pubkey, используется как один и тот же
    ///      - длина 66 байт: spend||view, оба compressed pubkey по 33 байта
    ///      Каждый pubkey: 1 байт (2/3) + 32 байта X.
    /// @param stealthMetaAddress bytes: 33 или 66 байт compressed pubkeys.
    /// @return stealthAddress EOA-адрес, куда слать средства.
    /// @return ephemeralPubKey compressed (33 байта) эпифемерный паблик.
    /// @return viewTag 1 байт из хэша shared secret.
    function generateStealthAddress(bytes memory stealthMetaAddress)
        external
        view
        returns (address stealthAddress, bytes memory ephemeralPubKey, bytes1 viewTag)
    {
        // 1. Парсим meta-address в два compressed pubkey
        (bytes memory spendCompressed, bytes memory viewCompressed) = _splitMetaAddress(stealthMetaAddress);

        // 2. Распаковываем их в (x, y)
        uint256 memPtr = Memory.allocate(0xC0); // 192 байта под инверсии и sqrt
        (uint256 spendX, uint256 spendY) = Secp256k1Arithmetic.decompressToAffinePoint(memPtr, spendCompressed);
        (uint256 viewX, uint256 viewY) = Secp256k1Arithmetic.decompressToAffinePoint(memPtr, viewCompressed);

        // sanity: должны лежать на кривой
        require(Secp256k1.isOnCurve(spendX, spendY), "invalid spend pubkey");
        require(Secp256k1.isOnCurve(viewX, viewY), "invalid view pubkey");

        // 3. Эфемерный приватный ключ (НЕ ДЕЛАТЬ ТАК В ПРОДЕ)
        uint256 ephemPriv =
            uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, stealthMetaAddress))) % Secp256k1.N;
        if (ephemPriv == 0) {
            ephemPriv = 1;
        }

        // 4. Эфемерный паблик: P_e = ephemPriv * G
        (uint256 eX, uint256 eY) = Secp256k1Arithmetic.mulAffinePoint(memPtr, Secp256k1.GX, Secp256k1.GY, ephemPriv);

        // 5. Shared secret: S = ephemPriv * P_view
        (uint256 sharedX, uint256 sharedY) = Secp256k1Arithmetic.mulAffinePoint(memPtr, viewX, viewY, ephemPriv);

        // 6. Хэш секрета + viewTag
        (uint256 sHash, bytes1 tag) = _hashSharedSecret(sharedX, sharedY);
        viewTag = tag;

        // 7. S_h = sHash * G
        (uint256 shX, uint256 shY) = Secp256k1Arithmetic.mulAffinePoint(memPtr, Secp256k1.GX, Secp256k1.GY, sHash);

        // 8. P_stealth = P_spend + S_h (в проективных координатах)
        (uint256 spendPX, uint256 spendPY, uint256 spendPZ) =
            Secp256k1Arithmetic.convertAffinePointToProjectivePoint(spendX, spendY);

        (uint256 shPX, uint256 shPY, uint256 shPZ) = Secp256k1Arithmetic.convertAffinePointToProjectivePoint(shX, shY);

        (uint256 resXProj, uint256 resYProj, uint256 resZProj) =
            Secp256k1Arithmetic.addProjectivePoint(spendPX, spendPY, spendPZ, shPX, shPY, shPZ);

        (uint256 stealthX, uint256 stealthY) =
            Secp256k1Arithmetic.convertProjectivePointToAffinePoint(memPtr, resXProj, resYProj, resZProj);

        // 9. Ethereum-адрес от полного паблика
        uint256 stealthAddrUint = Secp256k1.toAddress(stealthX, stealthY);
        stealthAddress = address(uint160(stealthAddrUint));

        // 10. Сжимаем эфемерный паблик в 33 байта
        uint256 memPtrOut = Memory.allocate(0x60); // 96 байт под compress
        ephemeralPubKey = Secp256k1Arithmetic.compressAffinePoint(memPtrOut, eX, eY);
    }

    /// @notice Проверяет, принадлежит ли stealth-адрес владельцу ключей.
    /// @dev viewingKey и spendingPubKey завязаны на secp256k1:
    ///      - viewingKey: 32-байтовый приватник (scalar mod N)
    ///      - spendingPubKey: 33 байта compressed pubkey
    function checkStealthAddress(
        address stealthAddress,
        bytes memory ephemeralPubKey,
        bytes memory viewingKey,
        bytes memory spendingPubKey
    ) external view returns (bool) {
        require(viewingKey.length == 32, "viewingKey must be 32 bytes");
        require(spendingPubKey.length == 33, "spend pubkey must be 33 bytes");

        uint256 memPtr = Memory.allocate(0xC0);

        // ephemeral pubkey -> (x, y)
        (uint256 eX, uint256 eY) = Secp256k1Arithmetic.decompressToAffinePoint(memPtr, ephemeralPubKey);

        // spend pubkey -> (x, y)
        (uint256 spendX, uint256 spendY) = Secp256k1Arithmetic.decompressToAffinePoint(memPtr, spendingPubKey);

        // viewing privkey -> scalar
        uint256 viewPriv;
        assembly {
            viewPriv := mload(add(viewingKey, 0x20))
        }
        require(Secp256k1.isValidNonZeroScalar(viewPriv), "invalid view privkey");

        // shared secret: S = viewPriv * P_e
        (uint256 sharedX, uint256 sharedY) = Secp256k1Arithmetic.mulAffinePoint(memPtr, eX, eY, viewPriv);

        (uint256 sHash,) = _hashSharedSecret(sharedX, sharedY);

        // S_h = sHash * G
        (uint256 shX, uint256 shY) = Secp256k1Arithmetic.mulAffinePoint(memPtr, Secp256k1.GX, Secp256k1.GY, sHash);

        // P_stealth = P_spend + S_h
        (uint256 spendPX, uint256 spendPY, uint256 spendPZ) =
            Secp256k1Arithmetic.convertAffinePointToProjectivePoint(spendX, spendY);

        (uint256 shPX, uint256 shPY, uint256 shPZ) = Secp256k1Arithmetic.convertAffinePointToProjectivePoint(shX, shY);

        (uint256 resXProj, uint256 resYProj, uint256 resZProj) =
            Secp256k1Arithmetic.addProjectivePoint(spendPX, spendPY, spendPZ, shPX, shPY, shPZ);

        (uint256 stealthX, uint256 stealthY) =
            Secp256k1Arithmetic.convertProjectivePointToAffinePoint(memPtr, resXProj, resYProj, resZProj);

        uint256 addrUint = Secp256k1.toAddress(stealthX, stealthY);
        return address(uint160(addrUint)) == stealthAddress;
    }

    /// @notice Считает приватный ключ stealth-адреса.
    /// @dev viewingKey и spendingKey — 32-байтовые приватники (scalars mod N).
    function computeStealthKey(
        address stealthAddress,
        bytes memory ephemeralPubKey,
        bytes memory viewingKey,
        bytes memory spendingKey
    ) external view returns (bytes memory stealthKey) {
        uint256 viewPriv = _bytesToScalar(viewingKey, "viewingKey must be 32 bytes");
        uint256 spendPriv = _bytesToScalar(spendingKey, "spendingKey must be 32 bytes");

        // p_stealth = p_spend + H(sharedSecret) (mod N)
        uint256 pStealth = _computeStealthScalar(ephemeralPubKey, viewPriv, spendPriv);

        // убеждаемся, что этот приватник реально даёт нужный stealthAddress
        _requireMatchingAddress(stealthAddress, pStealth);

        stealthKey = new bytes(32);
        assembly {
            mstore(add(stealthKey, 0x20), pStealth)
        }
    }

    /// @dev Конвертит 32-байтовый массив в скаляр secp256k1 с проверками.
    function _bytesToScalar(bytes memory key, string memory lenError) internal pure returns (uint256 scalar) {
        require(key.length == 32, lenError);
        assembly {
            scalar := mload(add(key, 0x20))
        }
        require(Secp256k1.isValidNonZeroScalar(scalar), "invalid scalar");
    }

    /// @dev Считает p_stealth = p_spend + H(p_view * P_e) (mod N).
    function _computeStealthScalar(bytes memory ephemeralPubKey, uint256 viewPriv, uint256 spendPriv)
        internal
        view
        returns (uint256 pStealth)
    {
        uint256 memPtr = Memory.allocate(0xC0);

        // 1. P_e из сжатого ключа
        (uint256 eX, uint256 eY) = Secp256k1Arithmetic.decompressToAffinePoint(memPtr, ephemeralPubKey);

        // 2. shared secret: S = viewPriv * P_e
        (uint256 sharedX, uint256 sharedY) = Secp256k1Arithmetic.mulAffinePoint(memPtr, eX, eY, viewPriv);

        // 3. H(S) и viewTag (viewTag тут не нужен, так что игнорим)
        (uint256 sHash,) = _hashSharedSecret(sharedX, sharedY);

        // 4. p_stealth = p_spend + H(S) (mod N)
        pStealth = addmod(spendPriv, sHash, Secp256k1.N);
    }

    /// @dev Проверяет, что приватник pStealth реально мапится в нужный stealthAddress.
    function _requireMatchingAddress(address stealthAddress, uint256 pStealth) internal view {
        uint256 memPtr = Memory.allocate(0xC0);

        (uint256 stealthX, uint256 stealthY) =
            Secp256k1Arithmetic.mulAffinePoint(memPtr, Secp256k1.GX, Secp256k1.GY, pStealth);

        uint256 addrUint = Secp256k1.toAddress(stealthX, stealthY);
        require(address(uint160(addrUint)) == stealthAddress, "stealth addr mismatch");
    }

    // --- internal helpers ---

    /// Разделяет meta-address на два compressed pubkey по 33 байта.
    function _splitMetaAddress(bytes memory meta)
        internal
        pure
        returns (bytes memory spendCompressed, bytes memory viewCompressed)
    {
        require(meta.length == 33 || meta.length == 66, "bad meta length");

        spendCompressed = new bytes(33);
        viewCompressed = new bytes(33);

        // первые 33 байта – всегда spending pubkey
        for (uint256 i = 0; i < 33; i++) {
            spendCompressed[i] = meta[i];
        }

        if (meta.length == 33) {
            // один и тот же ключ и для spend, и для view
            for (uint256 i = 0; i < 33; i++) {
                viewCompressed[i] = meta[i];
            }
        } else {
            // meta = spend(0..32) || view(33..65)
            for (uint256 i = 0; i < 33; i++) {
                viewCompressed[i] = meta[33 + i];
            }
        }
    }

    /// Хэш shared secret'а и извлечение viewTag.
    function _hashSharedSecret(uint256 sharedX, uint256 sharedY) internal pure returns (uint256 sHash, bytes1 viewTag) {
        // хэшируем (X, Y) через keccak256
        uint256 h = Hashes.efficientKeccak256(sharedX, sharedY);
        sHash = h;
        bytes32 hb = bytes32(h);
        // первый байт — viewTag (как в описании schemeId=1)
        viewTag = hb[0];
    }
}
