import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("Upgradeable token", function() {
  async function dep() {
    const [ deployer ] = await ethers.getSigners();

    const NFTFactory = await ethers.getContractFactory("MyToken");
    const token = await upgrades.deployProxy(NFTFactory, [], {
      initializer: 'initialize',
      kind: 'uups',
    });
    await token.deployed();

    return { token, deployer }
  }

  it('works', async function() {
    const { token, deployer } = await loadFixture(dep);

    const mintTx = await token.safeMint(deployer.address, "123abc");
    await mintTx.wait();

    expect(await token.balanceOf(deployer.address)).to.eq(1);

    const NFTFactoryv2 = await ethers.getContractFactory("MyTokenV2");
    const token2 = await upgrades.upgradeProxy(token.address, NFTFactoryv2);

    expect(await token2.balanceOf(deployer.address)).to.eq(1);
    expect(await token2.demo()).to.be.true;
    console.log(token.address);
    console.log(token2.address);
  });
});