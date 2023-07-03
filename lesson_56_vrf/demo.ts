import hre, { ethers } from "hardhat";

async function main() {
  // const Factory = await ethers.getContractFactory("Randomizer");
  // const rand = await Factory.deploy(12958);
  // await rand.waitForDeployment();

  // console.log(rand.target);

  const randAddr = "0x5BF0b9936E1c49C8Ff94CC01060C1c41D652590D";
  await hre.run("verify:verify", {
    address: randAddr,
    constructorArguments: [12958],
  });
}

main()
  .then(() => console.log("running"))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

