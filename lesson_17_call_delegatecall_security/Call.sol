// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {
    address otherContract;
    event Response(string response);

    constructor(address _otherContract) {
        otherContract = _otherContract;
    }

    function callReceive() external payable {
        (bool success, ) = otherContract.call{value: msg.value}("");
        require(success, "cant send funds!");
        // transfer --> 2300
    }

    function callSetName(string calldata _name) external {
        (bool success, bytes memory response) = otherContract.call(
            //abi.encodeWithSignature("setName(string)", _name)
            abi.encodeWithSelector(AnotherContract.setName.selector, _name)
        );

        require(success, "cant set name!");

        emit Response(abi.decode(response, (string)));
    }
}

contract AnotherContract {
    string public name;
    mapping (address => uint) public balances;

    function setName(string calldata _name) external returns(string memory) {
        name = _name;
        return name;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}