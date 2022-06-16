import { task, types } from 'hardhat/config';
import type { Demo } from '../typechain-types';
import { Demo__factory } from '../typechain-types/factories';

// DEMO 0x5FbDB2315678afecb367f032d93F642f64180aa3

task("balance", "Displays balance")
  .addParam('account', 'Account address')
  .addOptionalParam('greeting', 'Greeting to print',
    'Default greeting', types.string)
  .setAction(async (taskArgs, { ethers }) => {
    const account = taskArgs.account;
    const msg = taskArgs.greeting;

    console.log(msg);
    const balance = await ethers.provider.getBalance(account);

    console.log(balance.toString());
  });

task('callme', 'Call demo func')
  .addParam('contract', 'Contract address')
  .addOptionalParam('account', 'Account name', 'deployer', types.string)
  .setAction(async (taskArgs, { ethers, getNamedAccounts }) => {
    const account = (await getNamedAccounts())[taskArgs.account];

    const demo = Demo__factory.connect(
      taskArgs.contract,
      await ethers.getSigner(account)
    );

    console.log(await demo.callme());
  });

task('pay', 'Call pay func')
  .addParam('value', 'Value to send', 0, types.int)
  .addOptionalParam('account', 'Account name', 'deployer', types.string)
  .setAction(async (taskArgs, { ethers, getNamedAccounts }) => {
    const account = (await getNamedAccounts())[taskArgs.account];

    const demo = await ethers.getContract<Demo>('Demo', account);

    const tx = await demo.pay(`Hello from ${account}`, {value: taskArgs.value});
    await tx.wait();

    console.log(await demo.message());
    console.log((await ethers.provider.getBalance(demo.address)).toString());
  });

task('distribute', 'Distribute funds')
  .addParam('addresses', 'Addresses to distribute to')
  .setAction(async (taskArgs, { ethers }) => {
    const demo = await ethers.getContract<Demo>('Demo');

    const addrs = taskArgs.addresses.split(',');

    const tx = await demo.distribute(addrs);
    await tx.wait();

    await Promise.all(addrs.map(async (addr: string) => {
      console.log((await ethers.provider.getBalance(addr)).toString());
    }));
  });