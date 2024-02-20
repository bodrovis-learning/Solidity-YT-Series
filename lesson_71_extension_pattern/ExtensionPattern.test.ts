import { loadFixture, ethers, expect } from "./setup";
import { Extension__factory } from "../typechain-types";

describe("ExtensionPattern", function () {
  async function deploy() {
    const [owner] = await ethers.getSigners();

    const ExtFactory = await ethers.getContractFactory("Extension");
    const ext = await ExtFactory.deploy();
    await ext.waitForDeployment();

    const MainFactory = await ethers.getContractFactory("Main");
    const main = await MainFactory.deploy(ext.target);
    await main.waitForDeployment();

    const mainAsExt = Extension__factory.connect(
      await main.getAddress(),
      owner,
    );

    return { main, owner, ext, mainAsExt };
  }

  it("should delegate", async function () {
    const { mainAsExt, main } = await loadFixture(deploy);

    const tx = await mainAsExt.setB(4);
    const r = await tx.wait();
    console.log(`Simple ${r?.gasUsed}`);

    expect(await main.sum()).to.eq(5);
  });
});
