import { loadFixture, ethers, expect } from "./setup";

describe("ReentrCrossContract", function () {
  async function deploy() {
    const [hacker] = await ethers.getSigners();

    const CrossChainToken = await ethers.getContractFactory("CrossChainToken");

    const tokenA = await CrossChainToken.deploy();
    await tokenA.waitForDeployment();

    const tokenB = await CrossChainToken.deploy();
    await tokenB.waitForDeployment();

    const addCrossChainTx = await tokenA.addChainAddress(2, tokenB.target);
    await addCrossChainTx.wait();

    const AttackerCross = await ethers.getContractFactory("AttackerCross");
    const attacker = await AttackerCross.deploy(tokenA);
    await attacker.waitForDeployment();

    return { hacker, tokenA, tokenB, attacker };
  }

  it("hacks", async function () {
    const { hacker, tokenA, tokenB, attacker } = await loadFixture(deploy);

    const txMint = await tokenA.mint(attacker.target);
    await txMint.wait();

    // expect(await tokenA.ownerOf(1)).to.eq(hacker.address);
    // expect(await tokenA.currentTokenId()).to.eq(3n);
    console.log(await tokenA.ownerOf(1));
    console.log(await tokenA.ownerOf(2));
    console.log(await tokenA.ownerOf(3));
    const coder = new ethers.AbiCoder();

    // await expect(txMint)
    //   .to.emit(tokenA, "CrossChainTransfer")
    //   .withArgs(
    //     2,
    //     tokenB.target,
    //     coder.encode(
    //       ["uint256", "address", "address"],
    //       [1, attacker.target, hacker.address],
    //     ),
    //   );
  });
});
