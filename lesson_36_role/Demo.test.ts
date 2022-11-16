import { loadFixture, ethers, expect, time } from "./setup";
import type { Demo } from "../typechain-types";

describe("Demo", function() {
  async function deploy() {
    const [ superadmin, withdrawer, user ] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("Demo");
    const demo: Demo = await Factory.deploy(withdrawer.address);
    await demo.deployed();

    return { demo, withdrawer, user }
  }

  it('works', async function() {
    const { demo, withdrawer, user } = await loadFixture(deploy);
    const withdrawerRole = await demo.WITHDRAWER_ROLE();
    const defaultAdmin = await demo.DEFAULT_ADMIN_ROLE();
    expect(await demo.getRoleAdmin(withdrawerRole)).to.eq(defaultAdmin);

    await demo.connect(withdrawer).withdraw();

    await expect(demo.withdraw()).to.be.revertedWith('no such role!');
  });
});