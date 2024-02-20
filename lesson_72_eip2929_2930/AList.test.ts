import { loadFixture, ethers, expect } from "./setup";

describe("AList", function () {
  async function deploy() {
    const [owner] = await ethers.getSigners();

    const AList = await ethers.getContractFactory("AList");
    const list = await AList.deploy();
    await list.waitForDeployment();

    const Target = await ethers.getContractFactory("Target");
    const target = await Target.deploy();
    await target.waitForDeployment();

    return { list, target, owner };
  }

  it("simple", async function () {
    const { list, target } = await loadFixture(deploy);

    const tx = await list.callOther(await target.getAddress(), 42);
    const r = await tx.wait();

    console.log(`Simple ${r?.gasUsed}`);
  });

  it("complex", async function () {
    const { list, target } = await loadFixture(deploy);
    const addr = await target.getAddress();
    const coder = new ethers.AbiCoder();
    const tx = await list.callOther(await target.getAddress(), 42, {
      type: 1,
      accessList: [
        {
          address: addr,
          storageKeys: [coder.encode(["uint256"], [0])],
        },
      ],
    });
    const r = await tx.wait();

    console.log(`Complex ${r?.gasUsed}`);
  });
});
