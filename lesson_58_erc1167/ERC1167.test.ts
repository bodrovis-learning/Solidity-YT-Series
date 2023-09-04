import { loadFixture, ethers, expect } from "./setup";
import { Impl__factory } from "../typechain-types";

describe("ERC1167", function() {
  async function deploy() {
    const [user] = await ethers.getSigners();

    const ImplFactory = await ethers.getContractFactory("Impl");
    const impl = await ImplFactory.deploy();
    await impl.waitForDeployment();

    const MakerFactory = await ethers.getContractFactory("Maker");
    const maker = await MakerFactory.deploy();
    await maker.waitForDeployment();

    return { impl, maker, user }
  }

  it('should delegate', async function() {
    const { impl, maker, user } = await loadFixture(deploy);

    const implAddr = await impl.getAddress();

    const makeTx = await maker.make(implAddr);
    await makeTx.wait();
    
    const proxyAddr = await maker.lastDeployedAddr();

    const proxy = Impl__factory.connect(proxyAddr, user);

    expect(await proxy.a()).to.eq(0);

    const setATx = await proxy.callMe(123);
    await setATx.wait();

    expect(await proxy.a()).to.eq(123);
  });
});