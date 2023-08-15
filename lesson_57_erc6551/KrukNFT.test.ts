import { loadFixture, ethers, expect } from "./setup";
import { ERC6551Account__factory } from "../typechain-types";

describe("KrukNFT", function() {
  async function deploy() {
    const [ u1, u2 ] = await ethers.getSigners();

    const NFTFactory = await ethers.getContractFactory("KrukNFT");
    const nft = await NFTFactory.deploy();
    await nft.waitForDeployment();

    const AccountFactory = await ethers.getContractFactory("ERC6551Account");
    const account = await AccountFactory.deploy();
    await account.waitForDeployment();

    const RegistryFactory = await ethers.getContractFactory("ERC6551Registry");
    const registry = await RegistryFactory.deploy();
    await registry.waitForDeployment();

    return { u1, u2, nft, account, registry }
  }

  it('should work', async function() {
    const { u1, u2, nft, account, registry } = await loadFixture(deploy);

    console.log("OWNER", u1.address, "\n\n");

    const tokenId = 1;
    const salt = 123;

    const mintTx = await nft.safeMint(u1, tokenId);
    await mintTx.wait(1);

    expect(await nft.ownerOf(tokenId)).to.eq(u1.address);

    const expectedAddr = await registry.account(
      account.target,
      1337,
      nft.target,
      tokenId,
      salt
    );

    console.log("DEPLOYED TO", expectedAddr, "\n\n");

    const createTx = await registry.createAccount(
      account.target,
      1337,
      nft.target,
      tokenId,
      salt,
      "0x"
    );

    await createTx.wait(1);

    await expect(createTx).to.emit(registry, "AccountCreated").withArgs(
      expectedAddr,
      account.target,
      1337,
      nft.target,
      tokenId,
      salt,
    );

    const nftImpl = ERC6551Account__factory.connect(expectedAddr, u1);

    expect(await nftImpl.owner()).to.eq(u1.address);

    const value = 1000;

    const txData = {
      to: expectedAddr,
      value: value,
    };

    const txSendEth = await u1.sendTransaction(txData);
    await txSendEth.wait(1);

    expect(await ethers.provider.getBalance(expectedAddr)).to.eq(value);

    const sendToU2 = 150;

    const txDelegateSendEth = await nftImpl.execute(u2.address, sendToU2, "0x", 0);
    await txDelegateSendEth.wait(1);

    await expect(txDelegateSendEth).to.changeEtherBalance(u2, sendToU2);

    await expect(
      nftImpl.connect(u2).execute(u2.address, sendToU2, "0x", 0)
    ).to.be.revertedWith("Invalid signer");
  });
});