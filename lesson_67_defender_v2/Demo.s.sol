// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Demo.sol";

// forge script script/Demo.s.sol:DemoDeployScript --rpc-url sepolia --broadcast --verify -vvvv
contract DemoDeployScript is Script {
    function run() external {
        uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new Demo();

        vm.stopBroadcast();
    }
}
