import { ethers, Typed } from "ethers";

//v5
// import { providers } from "ethers"
// const { InfuraProvider } = providers

import { InfuraProvider } from "ethers";
// import { AbiCoder } from "ethers";

// const coder = AbiCoder.defaultAbiCoder()
// console.log(coder.encode(
//   ['string'], ['test']
// ));

const hex = ethers.toQuantity(BigInt(10));
console.log(hex);

const encoded = ethers.encodeBytes32String("test");
console.log(encoded);
console.log(ethers.decodeBytes32String(encoded));

//v5
//const hex = ethers.utils.hexValue(value)
// ethers.utils.formatBytes32String
// ethers.utils.parseBytes32String


const abi = [
  "function foo(address bar)",
  "function foo(uint160 bar)",
  "function bar(address addr)",
]

const contract = new ethers.Contract("0x...", abi, provider);
//contract.foo("0x000")
contract["foo(address)"]("0x0000") // OK, v5
contract["foo(address addr)"]("0x0000") // failed! v5

contract["foo(address)"]("0x0000") // OK, v6
contract["foo(address addr)"]("0x0000") // OK, v6
contract.foo(Typed.address("0x000")) // v6
contract.foo(Typed.uint160(100n));

// v5
// contract.staticCall.bar("0x000");
// contract.estimateGas.bar("0x000");

// v6

contract.bar.staticCall("0x000")
contract.bar.send("0x000")
contract.bar.estimateGas("0x000")