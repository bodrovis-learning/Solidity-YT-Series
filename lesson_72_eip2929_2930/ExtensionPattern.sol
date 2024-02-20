// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Main {
    uint256 a = 1;
    uint256 b;
    uint256 c;
    address private immutable extension;

    constructor(address _extension) {
        extension = _extension;
    }

    function sum() external view returns (uint256) {
        return a + b;
    }

    fallback(bytes calldata data) external payable returns (bytes memory) {
        (bool ok, bytes memory resp) = extension.delegatecall(data);
        if (ok) {
            return resp;
        }
        assembly {
            revert(add(32, resp), mload(resp))
        }
    }

    receive() external payable {}
}

contract Extension {
    uint256 a;
    uint256 b;
    uint256 c;
    address private extension;

    function setB(uint256 _b) external {
        require(_b > 0, "invalid");

        b = _b;
    }
}
