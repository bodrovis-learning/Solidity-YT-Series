import { loadFixture, ethers, expect, time } from "./setup";
import { ERC4907Demo } from "../typechain-types";

describe("ERC4907", function() {
  async function deploy() {
    const [ user1, user2 ] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("ERC4907Demo");
    const nft: ERC4907Demo = await Factory.deploy("MyToken", "MTK");

    return { nft, user1, user2 }
  }

  it("should work", async function() {
    const { nft, user1, user2 } = await loadFixture(deploy);

    const tokenId = 1;
    const u1_addr = user1.address;
    const u2_addr = user2.address;

    await nft.mint(tokenId, u1_addr);

    const expires = Math.floor(new Date().getTime() / 1000) + 100;

    await nft.setUser(tokenId, u2_addr, expires);

    expect(await nft.userOf(tokenId)).to.eq(u2_addr);
    expect(await nft.ownerOf(tokenId)).to.eq(u1_addr);

    await time.increase(102);

    expect(await nft.userOf(tokenId)).to.eq(
      ethers.constants.AddressZero
    );
  });
});