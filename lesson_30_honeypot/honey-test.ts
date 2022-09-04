import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import type { Bank, Attack, Logger, Honeypot } from "../typechain-types";

describe("Honey", function() {
  async function dep() {
    const [ deployer, attacker ] = await ethers.getSigners();

    const LoggerFactory = await ethers.getContractFactory("Logger");
    const logger: Logger = await LoggerFactory.deploy();
    await logger.deployed();

    const BankFactory = await ethers.getContractFactory("Bank");
    const bank: Bank = await BankFactory.deploy(logger.address);
    await bank.deployed();

    const AttackFactory = await ethers.getContractFactory("Attack");
    const attack: Attack = await AttackFactory.deploy(bank.address);
    await attack.deployed();

    const HoneypotFactory = await ethers.getContractFactory("Honeypot");
    const honeypot: Honeypot = await HoneypotFactory.deploy();
    await honeypot.deployed();

    const honeypotedBank: Bank = await BankFactory.deploy(honeypot.address);
    await honeypotedBank.deployed();

    const honeypotedAttack: Attack = await AttackFactory.deploy(
      honeypotedBank.address
    );
    await honeypotedAttack.deployed();

    return { bank,
      attack, deployer, attacker, honeypotedAttack,
      honeypot, honeypotedBank }
  };

  it('attacks', async function() {
    const { bank, attack, attacker } = await loadFixture(dep);

    const initialAmount = "5.0";

    const depositTx = await bank.deposit(
      {value: ethers.utils.parseEther(initialAmount)}
    );
    await depositTx.wait();

    const attackTx = await attack.connect(attacker).attack({
      value: ethers.utils.parseEther("1.0")
    });
    await attackTx.wait();

    const attackBalance = ethers.utils.formatEther(
      await attack.getBalance()
    );
    expect(attackBalance).to.eq("6.0");

    const afterAttackBalance = ethers.utils.formatEther(
      await bank.getBalance()
    );
    expect(afterAttackBalance).to.eq("0.0");
  });

  it('honeypots hacker', async function() {
    const { honeypotedBank, honeypotedAttack, attacker } =
      await loadFixture(dep);
    
    const initialAmount = "5.0";
    const depositTx = await honeypotedBank.deposit(
      {value: ethers.utils.parseEther(initialAmount)}
    );
    await depositTx.wait();

    const currentBalance = ethers.utils.formatEther(
      await honeypotedBank.getBalance()
    );
    expect(currentBalance).to.eq(initialAmount);

    await expect(
      honeypotedAttack.connect(attacker).
        attack({value: ethers.utils.parseEther("1.0")})
    ).to.be.revertedWith('Failed to send Ether');
  });

  // it('honeypots regular users', async function() {
  //   const { honeypotedBank } = await loadFixture(dep);

  //   const depositTx = await honeypotedBank.deposit(
  //     {value: ethers.utils.parseEther("5.0")}
  //   );
  //   await depositTx.wait();

  //   await expect(honeypotedBank.withdraw()).to.be.revertedWith('honeypot!');
  // });

  it('doesnt honeypot regular users', async function() {
    const { honeypotedBank, deployer } = await loadFixture(dep);

    const initialAmount = ethers.utils.parseEther("5.0");

    const depositTx = await honeypotedBank.deposit({value: initialAmount});
    await depositTx.wait();

    await expect(await honeypotedBank.withdraw()).
      to.changeEtherBalances(
        [honeypotedBank, deployer],
        [ethers.utils.parseEther("-5.0"), initialAmount]
      );
  });
});