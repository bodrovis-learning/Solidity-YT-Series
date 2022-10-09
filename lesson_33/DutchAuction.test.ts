import { loadFixture, ethers, expect, time } from "./setup";

describe("DutchAuction", function() {
  async function deploy() {
    const [ user ] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("DutchAuction");
    const auction = await Factory.deploy(
      1000000,
      1,
      "item"
    );
    await auction.deployed(); // 1

    return { auction, user }
  }

  it("allows to buy", async function() {
    const { auction, user } = await loadFixture(deploy);

    await time.increase(60); // 2

    const latest = await time.latest();
    const newLatest = latest + 1;
    await time.setNextBlockTimestamp(newLatest);

    const startPrice = await auction.startingPrice();
    const startAt = await auction.startAt();
    const elapsed = ethers.BigNumber.from(newLatest).sub(startAt);
    const discout = elapsed.mul(await auction.discountRate());
    const price = startPrice.sub(discout);

    const buyTx = await auction.buy({value: price.add(100)}); // 3
    await buyTx.wait();

    expect(
      await ethers.provider.getBalance(auction.address)
    ).to.eq(price);

    await expect(buyTx).to.changeEtherBalance(user, -price);
  });
});