import { loadFixture, ethers, expect, BigNumber, SignerWithAddress } from "./setup";
import type { Dispatch } from "../typechain-types";

describe("Dispatch", function() {
  async function deploy() {
    const [ user1 ] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("Dispatch");
    const disp: Dispatch = await Factory.deploy();
    await disp.deployed();

    return { user1, disp }
  }
  
  it("should dispatch", async function() {
    const { user1, disp } = await loadFixture(deploy);

    // const newA = 42;
    // const newABytes = ethers.utils.defaultAbiCoder.encode(["uint256"], [newA]);
    // const targetA = ethers.utils.formatBytes32String("a");
  
    // const updateATx = await disp.dispatch(targetA, newABytes);
    // await updateATx.wait();

    // expect(await disp.a()).to.eq(newA);
    // await expect(updateATx).to.emit(disp, "Dispatched").withArgs(targetA, newABytes);


    // const newB = 100;
    // const newBBytes = ethers.utils.defaultAbiCoder.encode(["uint256"], [newB]);
    // const targetB = ethers.utils.formatBytes32String("b");
    // const updateBTx = await disp.dispatch(targetB, newBBytes);
    // await updateBTx.wait();

    // expect(await disp.b()).to.eq(newB);
    // await expect(updateBTx).to.emit(disp, "Dispatched").withArgs(targetB, newBBytes);


    // const newAddr = disp.address;
    // const newAddrBytes = ethers.utils.defaultAbiCoder.encode(["address"], [newAddr]);
    // const targetAddr = ethers.utils.formatBytes32String("addr");
    // const updateAddrTx = await disp.dispatch(targetAddr, newAddrBytes);
    // await updateAddrTx.wait();

    // expect(await disp.addr()).to.eq(newAddr);
    // await expect(updateAddrTx).to.emit(disp, "Dispatched").withArgs(targetAddr, newAddrBytes);


    const newAddr = disp.address;
    const newAddrBytes = ethers.utils.defaultAbiCoder.encode(["address"], [newAddr]);

    const targetAddr = ethers.utils.formatBytes32String("addr");
    const updateAddrTx = await disp["dispatch(bytes32,address)"](targetAddr, newAddr);
    await updateAddrTx.wait();

    expect(await disp.addr()).to.eq(newAddr);
    await expect(updateAddrTx).to.emit(disp, "Dispatched").withArgs(targetAddr, newAddrBytes);



    // expect(await disp.addr()).to.eq(newAddr);
    // await expect(updateAddrTx).to.emit(disp, "Dispatched").withArgs(targetAddr, newAddrBytes);

    // const newSecret = ethers.utils.solidityKeccak256(["string"], ["test"]);
    // const targetSecret = ethers.utils.formatBytes32String("secret");
    // const updateSecretTx = await disp.dispatch(targetSecret, newSecret);
    // await updateSecretTx.wait();

    // expect(await disp.secret()).to.eq(newSecret);
    // await expect(updateSecretTx).to.emit(disp, "Dispatched").withArgs(targetSecret, newSecret);


    // const targetUnknown = ethers.utils.formatBytes32String("unknown");
    // await expect(
    //   disp.dispatch(targetUnknown, newSecret)
    // ).to.be.revertedWithCustomError(disp, "InvalidTarget").withArgs(targetUnknown);
  });
});