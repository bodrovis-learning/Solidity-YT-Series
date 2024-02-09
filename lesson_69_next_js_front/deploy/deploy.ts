import hre, { ethers } from "hardhat";

async function main() {
  console.log("DEPLOYING...");
  const [ deployer, owner ] = await ethers.getSigners();

  const MusicShop = await ethers.getContractFactory("MusicShop");
  const shop = await MusicShop.deploy(owner.address);
  await shop.waitForDeployment();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
