import { MinEthersFactory } from "../typechain-types/common";
import { loadFixture, ethers, expect, time } from "./setup";
import { BigNumber } from "ethers";

describe("Timelock", function() {
  async function deploy() {
    const [ owner ] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("Sample");
    const sample = await Factory.deploy();
    await sample.deployed();

    return { owner, sample }
  }

  async function getAt(addr: string, slot: number | string | BigNumber) {
    return await ethers.provider.getStorageAt(addr, slot);
  }

  it('checks state', async function () {
    const { owner, sample } = await loadFixture(deploy);

    const pos = ethers.BigNumber.from(
      ethers.utils.solidityKeccak256(
        ["uint256"],
        [1]
      )
    );
    const nextPos = pos.add(ethers.BigNumber.from(1));

    const mappingPos = ethers.utils.solidityKeccak256(
      ["uint256", "uint256"],
      [ethers.utils.hexZeroPad(sample.address, 32), 2]
    );
    const nonExistentMappingPos = ethers.utils.solidityKeccak256(
      ["uint256", "uint256"],
      [ethers.utils.hexZeroPad(owner.address, 32), 2]
    );
    const slots = [ 0, 1, 2, pos, nextPos, mappingPos, nonExistentMappingPos ];
    slots.forEach(async (slot) => {
      console.log(
        slot.toString(), "--->", await getAt(sample.address, slot)
      );
    });
  });
});