import * as dotenv from 'dotenv';
dotenv.config();

import { Wallet, utils } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

// npx hardhat deploy-zksync --script deploy --network zkTestnet
export default async function (hre: HardhatRuntimeEnvironment) {
  const PRIVATE_KEY = process.env.ZKS_PRIVATE_KEY || "";

  if (!PRIVATE_KEY) {
    throw new Error("Please set ZKS_PRIVATE_KEY in the environment variables.");
  }

  const wallet = new Wallet(PRIVATE_KEY);

  const deployer = new Deployer(hre, wallet);

  const artifact = await deployer.loadArtifact("DDemo");

  const secret = 42;
  const deploymentFee = await deployer.estimateDeployFee(artifact, [secret]);

  const tx = await deployer.zkWallet.deposit({
    to: deployer.zkWallet.address,
    token: utils.ETH_ADDRESS,
    amount: deploymentFee.mul(2)
  });

  await tx.wait();

  const contract = await deployer.deploy(artifact, [secret]);
  const addr = contract.address;
  console.log(addr);
}