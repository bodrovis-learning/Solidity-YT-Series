import { loadFixture, ethers, expect, time, anyValue } from "./setup";
import type { Payments } from "../typechain-types";

describe("Payments", function() {
  async function deploy() {
    const [ owner, receiver ] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("Payments");
    const payments: Payments = await Factory.deploy({
      value: ethers.utils.parseUnits("100", "ether")
    });

    return { owner, receiver, payments }
  }

  it("should allow to send and receive payments", async function() {
    const { owner, receiver, payments } = await loadFixture(deploy);

    const amount = ethers.utils.parseUnits("2", "ether");
    const nonce = 1;

    const hash = ethers.utils.solidityKeccak256(
      ["address", "uint256", "uint256", "address"],
      [receiver.address, amount, nonce, payments.address]
    );

    // console.log('hash -->', ethers.utils.solidityKeccak256(
    //   ["string", "bytes32"],
    //   ["\x19Ethereum Signed Message:\n32", hash]
    // ));

    const messageHashBin = ethers.utils.arrayify(hash);
    const signature = await owner.signMessage(messageHashBin);
    console.log(signature)

    const tx = await payments.connect(receiver).claim(amount, nonce, signature);
    await tx.wait();

    expect(tx).to.changeEtherBalance(receiver, amount);
  });
});