const { ethers } = require('ethers');
const { Defender } = require('@openzeppelin/defender-sdk');

const ABI = ["function deposit() external payable"];
const ADDRESS = "0x440DE436B39a4E91d15338e7652cE10cD48CF961";

exports.main = async function(signer) {
  const contract = new ethers.Contract(ADDRESS, ABI, signer);

  const tx = await contract.deposit({value: 1});

  console.log(`Sent transaction ${tx.hash}`);
  return tx.hash;
}

exports.handler = async function(params) {
  const client = new Defender(params);
  const provider = client.relaySigner.getProvider();
  const signer = client.relaySigner.getSigner(provider);

  return exports.main(signer);  
}

// exports.handler = async function(credentials) {
//   const relayer = new Relayer(credentials);
//   return exports.main(relayer);  
// }