import type { AddressLike, EventLog, SignerWithAddress } from "./setup";
import { LPToken__factory } from "../typechain-types";
import { ethers, expect, loadFixture, mine, time } from "./setup";

describe("Governor", () => {
	async function deploy() {
		const [admin, user1, user2] = await ethers.getSigners();

		const GTK = await ethers.getContractFactory("GTK");
		const gtk = await GTK.deploy(50);
		await gtk.waitForDeployment();

    const WETH = await ethers.getContractFactory("WETH");
		const weth = await WETH.deploy();
		await weth.waitForDeployment();

    const SimpleDEX = await ethers.getContractFactory("SimpleDEX");
		const dex = await SimpleDEX.deploy(weth.target, gtk.target);
		await dex.waitForDeployment();

    return { admin, user1, user2, gtk, weth, dex }
  }

  it("works", async () => {
		const { admin, user1, user2, gtk, weth, dex } = await loadFixture(deploy);

    const lpToken = LPToken__factory.connect(await dex._lpToken(), admin);

    const wethToBuy = ethers.parseEther("20.0");
    const wethBuy = await weth.connect(user1).deposit({value: wethToBuy});
    await wethBuy.wait();

    await expect(wethBuy).to.changeEtherBalances([user1, weth], [-wethToBuy, wethToBuy]);
    expect(await weth.balanceOf(user1.address)).to.eq(wethToBuy);

    const transferGtkU1 = await gtk.transfer(user1.address, ethers.parseEther("15.0"));
    await transferGtkU1.wait();

    const transferGtkU2 = await gtk.transfer(user2.address, ethers.parseEther("15.0"));
    await transferGtkU2.wait();

    const liqAmount = ethers.parseEther("10.0");
    const approveWeth = await weth.connect(user1).approve(dex.target, liqAmount);
    await approveWeth.wait();
    const approveGtk = await gtk.connect(user1).approve(dex.target, liqAmount);
    await approveGtk.wait();

    const addLiq = await dex.connect(user1).addLiquidity(liqAmount, liqAmount);
    await addLiq.wait();

    expect(await lpToken.balanceOf(user1.address)).to.eq(liqAmount);

    const swapAmount1 = ethers.parseEther("5.0");
    const approveGtkForSwap = await gtk.approve(dex.target, swapAmount1);
    await approveGtkForSwap.wait();
    const swapGTKToWETH = await dex.swapTokenAForWETH(swapAmount1);
    const swapReceipt = await swapGTKToWETH.wait();
    
    console.log(swapReceipt?.logs);



    const wethToBuy2 = ethers.parseEther("10.0");
    const wethBuy2 = await weth.connect(user2).deposit({value: wethToBuy2});
    await wethBuy2.wait();


    const wethToSwap = wethToBuy2;
    const approveWETHForSwap = await weth.connect(user2).approve(dex.target, wethToSwap);
    await approveWETHForSwap.wait();
    const swapWETHToGtk = await dex.connect(user2).swapWETHForTokenA(wethToSwap);
    const swapReceipt2 = await swapWETHToGtk.wait();

    console.log(swapReceipt2?.logs);

    const liqToRemove = ethers.parseEther("4.0");
    const removeLiqApprove = await lpToken.connect(user1).approve(dex.target, wethToBuy2);
    await removeLiqApprove.wait();

    const removeLiq = await dex.connect(user1).removeLiquidity(liqToRemove);
    const removeLiqReceipt = await removeLiq.wait();

    console.log(removeLiqReceipt?.logs);
  });
});