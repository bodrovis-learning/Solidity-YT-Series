import { loadFixture, ethers, SignerWithAddress, expect } from "./setup";
import type { LazyNFT } from "../typechain-types";

interface LazyRedeemMessage {
  tokenId: number | string;
  minPrice: number;
  uri: string;
}

interface RSV { 
  r: string;
  s: string;
  v: number;
}

interface Domain {
  name: string;
  version: string;
  chainId: number;
  verifyingContract: string;
}

function splitSignatureToRSV(signature: string): RSV {
  const r = '0x' + signature.substring(2).substring(0, 64);
  const s = '0x' + signature.substring(2).substring(64, 128);
  const v = parseInt(signature.substring(2).substring(128, 130), 16);

  return { r, s, v };
}

async function signLazyMint(
  token: string,
  tokenId: string | number,
  minPrice: number,
  uri: string,
  signer: SignerWithAddress
): Promise<LazyRedeemMessage & RSV> {
  const message: LazyRedeemMessage = {
    tokenId,
    minPrice,
    uri,
  };

  const domain: Domain = {
    name: "LazyNFT",
    version: "1",
    chainId: 1337,
    verifyingContract: token,
  };

  const typedData = createTypedData(message, domain);

  const rawSignature = await signer._signTypedData(
    typedData.domain,
    typedData.types,
    typedData.message
  );

  const sig = splitSignatureToRSV(rawSignature);

  return { ...sig, ...message };
}

function createTypedData(message: LazyRedeemMessage, domain: Domain) {
  return {
    types: {
      NFTVoucher: [
        { name: "tokenId", type: "uint256" },
        { name: "minPrice", type: "uint256" },
        { name: "uri", type: "string" },
      ]
    },
    primaryType: "NFTVoucher",
    domain,
    message,
  };
}

describe("LazyNFT", function() {
  async function deploy() {
    const [ user1, user2 ] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("LazyNFT");
    const token: LazyNFT = await Factory.deploy("LazyNFT", "LFT");

    return { token, user1, user2 }
  }

  it('should redeem', async function() {
    const { token, user1, user2 } = await loadFixture(deploy);

    const owner = user1.address;
    const tokenAddr = token.address;
    const redeemer = user2.address;
    const tokenId = 0;
    const minPrice = 1000;
    const uri = 'http://example.com/123';

    const result = await signLazyMint(
      tokenAddr,
      tokenId,
      minPrice,
      uri,
      user1,
    );

    const tx = await token.connect(user2).redeem(
      owner,
      redeemer,
      result.tokenId,
      result.minPrice,
      result.uri,
      result.v,
      result.r,
      result.s,
      { value: minPrice },
    );
    await tx.wait();

    expect(await token.ownerOf(tokenId)).to.eq(redeemer);
    expect(await token.availableToWithdraw(owner)).to.eq(minPrice);
    expect(await token.tokenURI(tokenId)).to.eq(uri);
  });
});