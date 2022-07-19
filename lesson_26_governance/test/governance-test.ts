import { expect } from "chai";
import { ethers, deployments, network } from 'hardhat';
import { Demo, Governance } from '../typechain-types';

describe('MShop', function() {
  let governance: Governance;
  let demo: Demo;

  beforeEach(async function() {
    await deployments.fixture(['MyToken', 'Governance', 'Demo']);

    governance = await ethers.getContract<Governance>('Governance');
    demo = await ethers.getContract<Demo>('Demo');
  });

  it("works", async function() {
    const proposeTx = await governance.propose(
      demo.address,
      10,
      "pay(string)",
      ethers.utils.defaultAbiCoder.encode(['string'], ['test']),
      "Sample proposal"
    );

    const proposalData = await proposeTx.wait();

    const proposalId = proposalData.events?.[0].args?.proposalId.toString();

    const sendTx = await ethers.provider.getSigner(0).sendTransaction({
      to: governance.address,
      value: 10
    });
    await sendTx.wait();

    await network.provider.send("evm_increaseTime", [11]);

    const voteTx = await governance.vote(proposalId, 1);
    await voteTx.wait();

    await network.provider.send("evm_increaseTime", [70]);
    const executeTx = await governance.execute(
      demo.address,
      10,
      "pay(string)",
      ethers.utils.defaultAbiCoder.encode(['string'], ['test']),
      ethers.utils.solidityKeccak256(['string'], ["Sample proposal"])
    );

    await executeTx.wait();

    expect(await demo.message()).to.eq("test");
    expect(await demo.balances(governance.address)).to.eq(10);
  });
});