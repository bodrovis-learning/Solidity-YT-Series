import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Sample, Sample__factory } from "../typechain-types";

describe("Sample", function() {
  async function deploy() {
    const [ deployer, user ] = await ethers.getSigners();

    const SampleFactory = await ethers.getContractFactory("Sample");
    const sample: Sample = await SampleFactory.deploy();
    await sample.deployed();

    return { sample, deployer, user }
  }

  it("allows to call get()", async function() {
    const { sample, deployer } = await loadFixture(deploy);
    
    expect(await sample.get()).to.eq(42);
  });

  it("allows to call pay() and message()", async function() {
    const { sample, deployer } = await loadFixture(deploy);
    
    const value = 1000;
    const tx = await sample.pay("hi", {value: value});
    await tx.wait();

    expect(await sample.get()).to.eq(value);
    expect(await sample.message()).to.eq("hi");
  });

  it("allows to call callMe()", async function() {
    const { sample, user } = await loadFixture(deploy);
    
    const sampleAsUser = Sample__factory.connect(sample.address, user);
    const tx = await sampleAsUser.callMe();
    await tx.wait();

    expect(await sampleAsUser.caller()).to.eq(user.address);
  });

  it("reverts call to callError() with Panic", async function() {
    const { sample, deployer } = await loadFixture(deploy);
    
    await expect(sample.callError()).to.be.revertedWithPanic();
  });
});