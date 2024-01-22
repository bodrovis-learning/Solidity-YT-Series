// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./AccessManaged.sol";
import "./IAccessManager.sol";

contract Demo is AccessManaged {
    bool public nonSecretCalled;
    bool public secretCalled;
    bool public delayedCalled;
    IAccessManager private _currentAuthority;

    constructor(address initialAuthority) AccessManaged(initialAuthority) {
        _currentAuthority = IAccessManager(initialAuthority);
    }

    function nonSecret() external {
        nonSecretCalled = true;
    }

    function secret() external restricted {
        secretCalled = true;
    }

    function delayed() external restricted {
        delayedCalled = true;
    }
}
