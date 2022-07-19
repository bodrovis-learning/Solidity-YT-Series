import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;

  const { deploy, get } = deployments;

  const { deployer } = await getNamedAccounts();

  await deploy("Demo", {
    from: deployer,
    log: true
  });

  const govern = await get("Governance");

  const demo = await hre.ethers.getContract(
    "Demo",
    deployer
  );

  const tx = await demo.transferOwnership(govern.address);
  await tx.wait();
}

export default func;
func.tags = ['Demo'];