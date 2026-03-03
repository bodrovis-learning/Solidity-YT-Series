// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// forge-std
import "forge-std/Test.sol";

// frost-secp256k1-evm
import {Memory} from "frost-secp256k1-evm/utils/Memory.sol";
import {Secp256k1} from "frost-secp256k1-evm/utils/cryptography/Secp256k1.sol";
import {Secp256k1Arithmetic} from "frost-secp256k1-evm/utils/cryptography/Secp256k1Arithmetic.sol";

// Твой контракт (путь поправь под себя)
import {ERC5564Secp256k1} from "../src/ERC5564Secp256k1.sol";

contract ERC5564Secp256k1Test is Test {
    ERC5564Secp256k1 internal stealth;

    uint256 internal spendPriv;
    uint256 internal viewPriv;

    bytes internal spendCompressed;
    bytes internal viewCompressed;
    bytes internal metaAddress;

    function setUp() public {
        stealth = new ERC5564Secp256k1();

        spendPriv = uint256(keccak256("spend-key")) % Secp256k1.N;
        viewPriv = uint256(keccak256("view-key")) % Secp256k1.N;
        if (spendPriv == 0) spendPriv = 1;
        if (viewPriv == 0) viewPriv = 2;

        // считаем паблики через frost-secp256k1-evm
        uint256 memPtr = Memory.allocate(0xC0);

        (uint256 spendX, uint256 spendY) =
            Secp256k1Arithmetic.mulAffinePoint(memPtr, Secp256k1.GX, Secp256k1.GY, spendPriv);
        (uint256 viewX, uint256 viewY) =
            Secp256k1Arithmetic.mulAffinePoint(memPtr, Secp256k1.GX, Secp256k1.GY, viewPriv);

        // compress to 33 bytes
        uint256 memPtr2 = Memory.allocate(0x60);
        spendCompressed = Secp256k1Arithmetic.compressAffinePoint(memPtr2, spendX, spendY);
        viewCompressed = Secp256k1Arithmetic.compressAffinePoint(memPtr2, viewX, viewY);

        // meta = spend || view
        metaAddress = abi.encodePacked(spendCompressed, viewCompressed);

        // sanity
        assertEq(spendCompressed.length, 33);
        assertEq(viewCompressed.length, 33);
        assertEq(metaAddress.length, 66);
    }

    /// Полный позитивный путь:
    /// - generateStealthAddress
    /// - checkStealthAddress
    /// - computeStealthKey
    /// и сверка, что приватник даёт тот же адрес.
    function testGenerateCheckComputeStealthAddress() public {
        // фиксируем msg.sender, чтобы эфемерный ключ был детерминированным
        vm.prank(address(0xBEEF));

        (address stealthAddr, bytes memory ephemPub,) = stealth.generateStealthAddress(metaAddress);

        // базовые проверки
        assertTrue(stealthAddr != address(0), "stealth address is zero");
        assertEq(ephemPub.length, 33, "ephemeral pubkey must be 33 bytes");

        // собираем viewing private key в bytes
        bytes memory viewKeyBytes = abi.encodePacked(bytes32(viewPriv));
        // spending pubkey сюда идёт в сжатом виде (33 байта)
        bytes memory spendPubBytes = spendCompressed;

        // checkStealthAddress должен вернуть true
        bool ok = stealth.checkStealthAddress(stealthAddr, ephemPub, viewKeyBytes, spendPubBytes);
        assertTrue(ok, "checkStealthAddress must be true for correct keys");

        // computeStealthKey должен вернуть приватник, который реально даёт этот же stealthAddr
        bytes memory spendKeyBytes = abi.encodePacked(bytes32(spendPriv));
        bytes memory stealthPrivBytes = stealth.computeStealthKey(stealthAddr, ephemPub, viewKeyBytes, spendKeyBytes);

        assertEq(stealthPrivBytes.length, 32, "stealth priv key must be 32 bytes");

        uint256 stealthPriv;
        assembly {
            stealthPriv := mload(add(stealthPrivBytes, 0x20))
        }

        // восстанавливаем адрес из этого приватника и сверяем
        uint256 memPtr = Memory.allocate(0xC0);
        (uint256 sx, uint256 sy) = Secp256k1Arithmetic.mulAffinePoint(memPtr, Secp256k1.GX, Secp256k1.GY, stealthPriv);
        uint256 addrUint = Secp256k1.toAddress(sx, sy);
        address derivedAddr = address(uint160(addrUint));

        assertEq(derivedAddr, stealthAddr, "address from computed stealth key must equal stealthAddr");
    }

    /// Негативный кейс: подсовываем неправильный viewing key,
    /// checkStealthAddress должен вернуть false.
    function testCheckStealthAddressWrongViewingKey() public {
        vm.prank(address(0xBEEF));
        (address stealthAddr, bytes memory ephemPub,) = stealth.generateStealthAddress(metaAddress);

        // кривой viewing приватник
        uint256 wrongViewPriv = (viewPriv + 123456789) % Secp256k1.N;
        if (wrongViewPriv == 0) wrongViewPriv = 42;

        bytes memory wrongViewKeyBytes = abi.encodePacked(bytes32(wrongViewPriv));

        bool ok = stealth.checkStealthAddress(stealthAddr, ephemPub, wrongViewKeyBytes, spendCompressed);

        assertFalse(ok, "checkStealthAddress must be false for wrong viewing key");
    }

    /// Тестформат meta-address длиной 33 байта:
    /// один и тот же паблик используется и как spend, и как view.
    function testGenerateWithSinglePubkeyMetaAddress() public {
        // берём spendPriv как общий
        uint256 commonPriv = spendPriv;

        uint256 memPtr = Memory.allocate(0xC0);
        (uint256 x, uint256 y) = Secp256k1Arithmetic.mulAffinePoint(memPtr, Secp256k1.GX, Secp256k1.GY, commonPriv);

        uint256 memPtr2 = Memory.allocate(0x60);
        bytes memory singleCompressed = Secp256k1Arithmetic.compressAffinePoint(memPtr2, x, y);

        assertEq(singleCompressed.length, 33);

        // meta длиной 33 → контракт внутри должен продублировать pubkey и для view
        vm.prank(address(0xBEEF));
        (address stealthAddr, bytes memory ephemPub,) = stealth.generateStealthAddress(singleCompressed);

        assertTrue(stealthAddr != address(0), "stealthAddr must not be zero");
        assertEq(ephemPub.length, 33, "ephem pubkey length must be 33");
    }

    /// Тест на некорректную длину meta-address: должны словить require.
    function testRevertOnBadMetaLength() public {
        // 10 байт мусора
        bytes memory badMeta = hex"0102030405060708090a";

        vm.expectRevert("bad meta length");
        stealth.generateStealthAddress(badMeta);
    }

    /// Доп. чек: computeStealthKey кидает, если адрес не совпал
    /// (мы подделаем stealthAddress и ждём revert).
    function testComputeStealthKeyRevertOnMismatchAddress() public {
        vm.prank(address(0xBEEF));
        (address stealthAddr, bytes memory ephemPub,) = stealth.generateStealthAddress(metaAddress);

        bytes memory viewKeyBytes = abi.encodePacked(bytes32(viewPriv));
        bytes memory spendKeyBytes = abi.encodePacked(bytes32(spendPriv));

        address fakeAddr = address(uint160(uint256(keccak256("fake-stealth"))));

        vm.expectRevert("stealth addr mismatch");
        stealth.computeStealthKey(fakeAddr, ephemPub, viewKeyBytes, spendKeyBytes);

        // а с настоящим адресом — всё ок
        bytes memory keyOk = stealth.computeStealthKey(stealthAddr, ephemPub, viewKeyBytes, spendKeyBytes);
        assertEq(keyOk.length, 32);
    }

    /// E2E: шлём ETH на stealth-адрес и потом "забираем" их,
    /// используя приватник, который вернул computeStealthKey.
    function testSendAndWithdrawEthThroughStealthAddress() public {
        // 1) Генерим stealth-адрес (эпифемерный ключ зависит от msg.sender)
        vm.prank(address(0xBEEF));
        (address stealthAddr, bytes memory ephemPub,) = stealth.generateStealthAddress(metaAddress);

        assertTrue(stealthAddr != address(0), "stealthAddr is zero");

        // 2) У нас есть отправитель с балансом
        address sender = address(0xABCD);
        deal(sender, 5 ether);

        // 3) Отправитель шлёт 1 ETH на stealth-адрес
        vm.prank(sender);
        (bool ok,) = stealthAddr.call{value: 1 ether}("");
        require(ok, "send to stealthAddr failed");

        assertEq(stealthAddr.balance, 1 ether, "stealthAddr must hold 1 ETH after send");

        // 4) Получатель восстанавливает приватник stealth-адреса
        // viewing / spending приватники у нас уже есть в setUp:
        //   viewPriv, spendPriv
        bytes memory viewKeyBytes = abi.encodePacked(bytes32(viewPriv));
        bytes memory spendKeyBytes = abi.encodePacked(bytes32(spendPriv));

        bytes memory stealthPrivBytes = stealth.computeStealthKey(stealthAddr, ephemPub, viewKeyBytes, spendKeyBytes);

        assertEq(stealthPrivBytes.length, 32, "stealth priv key length != 32");

        uint256 stealthPriv;
        assembly {
            stealthPriv := mload(add(stealthPrivBytes, 0x20))
        }

        // 5) Проверяем, что этот приватник реально даёт наш stealthAddr
        address ownerAddr = vm.addr(stealthPriv);
        assertEq(ownerAddr, stealthAddr, "vm.addr(stealthPriv) must equal stealthAddr");

        // 6) Теперь "владелец" (EOA с этим приватником) выводит часть средств
        address receiver = address(0xCAFE);

        vm.prank(ownerAddr);
        (ok,) = receiver.call{value: 0.6 ether}("");
        require(ok, "withdraw from stealthAddr failed");

        // 7) Проверяем балансы после вывода
        assertEq(stealthAddr.balance, 0.4 ether, "stealthAddr balance after withdraw");
        assertEq(receiver.balance, 0.6 ether, "receiver balance after withdraw");
    }
}
