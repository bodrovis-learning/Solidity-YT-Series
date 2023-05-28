import hre, { ethers } from "hardhat";
import type { MyToken } from "../typechain-types";

import {
  DefenderRelaySigner,
  DefenderRelayProvider }
from 'defender-relay-client/lib/ethers';

async function main() {
  const tokenAddr = "0x8cE6E5CBf50e058F94868f47d88fDE4aeEAC2d09";
  // const owner = "0x719C2d2bcC155c85190f20E1Cc3710F90FAFDa16";
  // const Factory = await ethers.getContractFactory("MyToken");
  // const dep = await Factory.deploy();
  // await dep.deployed();
  // console.log(dep.address);

  // await hre.run("verify:verify", {
  //   address: tokenAddr,
  // });

  const mtk: MyToken = await ethers.getContractAt("MyToken", tokenAddr);
  // //console.log(await mtk.hasRole(await mtk.DEFAULT_ADMIN_ROLE(), owner));
  console.log(await mtk.ownerOf(0));
  // const relayerAddr = '0xd96fff93322c7b99bffddd5e76b51e0b8fa92d33';
  
  // const credentials = {
  //   apiKey: 'Epiv7iYCE5CHpPSq8As137bhnP45Qsdu',
  //   apiSecret: '4us12mhJqvMmpkkS5MUL1zeKHywgEiVBuso6E5CvYbtbV8sRADHqseUsZ6UMWz34',
  // };

  // const provider = new DefenderRelayProvider(credentials);
  // const signer = new DefenderRelaySigner(credentials, provider);
  
  // const relayAddr = await signer.getAddress();

  // const minterRole = await mtk.MINTER_ROLE();
  // // const pauserRole = await mtk.PAUSER_ROLE();
  // const txGrant = await mtk.grantRole(minterRole, relayAddr);
  // await txGrant.wait(1);

  // console.log(await mtk.hasRole(minterRole, relayAddr));

  // const revokeTx = await mtk.revokeRole(await mtk.PAUSER_ROLE(), relayAddr);
  // await revokeTx.wait(1);
}

main()
  .then(() => console.log("running"))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


// RELAYER


// const { ethers } = require('ethers');
// const { DefenderRelaySigner, DefenderRelayProvider } = require('defender-relay-client/lib/ethers');

// const ABI = ["function safeMint(address to) public"];
// const TO = "0x719C2d2bcC155c85190f20E1Cc3710F90FAFDa16";
// const ADDRESS = "0x8cE6E5CBf50e058F94868f47d88fDE4aeEAC2d09";

// async function main(signer, to) {
//   const nft = new ethers.Contract(ADDRESS, ABI, signer);

//   const tx = await nft.safeMint(to);

//   console.log(tx.hash);
// }

// exports.handler = async function(params) {
//   const provider = new DefenderRelayProvider(params); 
//   const signer = new DefenderRelaySigner(params, provider);

//   await main(signer, TO);
// }
