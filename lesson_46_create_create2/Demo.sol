//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Factory {
    bytes32 immutable SALT;

    event Deployed(address to);

    constructor(string memory _salt) {
        SALT = bytes32(bytes(_salt));
    }

    function deploy() external {
        // address to = address(
        //     new Target{salt: SALT}()
        // );

        address targetCreator = address(
            new TargetCreator{salt: SALT}()
        );
        // 0xffF3aB3867FC09a5715337934C07e349C6780A10
        // 0xffF3aB3867FC09a5715337934C07e349C6780A10

        emit Deployed(targetCreator);
    }

    function calcAddr() external view returns(address) {
        bytes32 h = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                SALT,
                keccak256(getBytecode())
            )
        );

        return address(uint160(uint256(h)));
    }

    function getBytecode() public pure returns(bytes memory) {
        bytes memory bc = type(Target).creationCode;

        return abi.encodePacked(bc);
    }

    receive() external payable {}
}

contract TargetCreator {
    address parent;

    event TargetDeployed(address to);

    constructor() {
        parent = msg.sender;
    }

    function deployTarget() external {
        address target = address(
            new Target()
        );
        // 0xdbdACC32C5E98615768BC3296a38f51CA9f98195

        emit TargetDeployed(target);
    }

    function deployNewTarget() external {
        address newTarget = address(
            new NewTarget()
        );
        // 0xdbdACC32C5E98615768BC3296a38f51CA9f98195

        emit TargetDeployed(newTarget);
    }

    function destroy() external {
        selfdestruct(payable(parent));
    }
}

contract Target {
    address parent;
    uint public a;

    constructor() {
        parent = msg.sender;
    }

    function withdraw() external {
        (bool ok, ) = parent.call{value: address(this).balance}("");
        require(ok, "failed!");
    }

    function setA(uint _a) external {
        a = _a;
    }

    function destroy() external {
        selfdestruct(payable(parent));
    }

    receive() external payable {}
}

// Factory --> (create2) TargetCreator --> (create) Target
// create:
// 1. nonce
// 2. deployer address

contract NewTarget {
    address public parent;
    uint public a;

    constructor() {
        parent = msg.sender;
    }

    function withdraw(address _to) external {
        (bool ok, ) = _to.call{value: address(this).balance}("");
        require(ok, "failed to withdraw!");
    }

    function setA(uint _a) external {
        a = _a;
    }

    receive() external payable {}
}