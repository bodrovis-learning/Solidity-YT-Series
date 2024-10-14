import type { GovernToken } from "../typechain-types";
import type { AddressLike, EventLog, SignerWithAddress } from "./setup";
import { ethers, expect, loadFixture, mine, time } from "./setup";

async function transferWithDecimals(
	token: GovernToken,
	sender: SignerWithAddress,
	receiver: AddressLike,
	baseAmount: bigint,
) {
	const decimals = await token.decimals();

	const transferTx = await token
		.connect(sender)
		.transfer(receiver, baseAmount * 10n ** decimals);
	await transferTx.wait();
}

describe("Governor", () => {
	async function deploy() {
		const [admin, user1, user2] = await ethers.getSigners();

		const name = "GuideDAO";
		const symbol = "GTK";

		const GovernToken = await ethers.getContractFactory("GovernToken");
		const token = await GovernToken.deploy(name, symbol);
		await token.waitForDeployment();

		const Timelock = await ethers.getContractFactory("Timelock");
		const timelock = await Timelock.deploy(3600, [], [], admin.address);
		await timelock.waitForDeployment();

		const GuideGovernor = await ethers.getContractFactory("GuideGovernor");
		const governor = await GuideGovernor.deploy(token.target, timelock.target);
		await governor.waitForDeployment();

		const grantPropRole = await timelock.grantRole(
			await timelock.PROPOSER_ROLE(),
			governor.target,
		);
		await grantPropRole.wait();

		const grantExecRole = await timelock.grantRole(
			await timelock.EXECUTOR_ROLE(),
			ethers.ZeroAddress,
		);
		await grantExecRole.wait();

		const renounceDefAdmin = await timelock.renounceRole(
			await timelock.DEFAULT_ADMIN_ROLE(),
			admin.address,
		);
		await renounceDefAdmin.wait();

		const Storage = await ethers.getContractFactory("Storage");
		const storage = await Storage.deploy(timelock.target, {
			value: ethers.parseEther("2.0"),
		});
		await storage.waitForDeployment();

		return { token, timelock, governor, storage, admin, user1, user2 }
	}

	it("works", async () => {
		const { token, timelock, governor, storage, admin, user1, user2 } = await loadFixture(deploy);

		const storageBalance = ethers.parseEther("2.0");
		expect(await ethers.provider.getBalance(storage.target)).to.eq(storageBalance);

		await transferWithDecimals(token, admin, user1.address, 10n);
		await transferWithDecimals(token, admin, user2.address, 20n);

		const del1 = await token.connect(user1).delegate(user1.address);
		await del1.wait();

		const del2 = await token.connect(user2).delegate(user2.address);
		await del2.wait();

		const del3 = await token.connect(admin).delegate(user2.address);
		await del3.wait();

		expect(await token.numCheckpoints(user1)).to.eq(1n);
		expect(await token.numCheckpoints(user2)).to.eq(2n);

		const storeFuncCall = storage.interface.encodeFunctionData("store", [42n]);
		console.log(storeFuncCall);
		const sendMoneyFuncCall = storage.interface.encodeFunctionData("sendMoney", [user2.address, storageBalance]);

		const targets = [storage.target, storage.target];

		const values = [0, 0];
		const calldatas = [storeFuncCall, sendMoneyFuncCall];
		const description = "Let's store 42 and send money to user2!";
		const descriptionHash = ethers.keccak256(ethers.toUtf8Bytes(description));

		const proposeTx = await governor.propose(
			targets,
			values,
			calldatas,
			description,
		);
		const proposalReceipt = await proposeTx.wait();

		const expectedProposalId = await governor.hashProposal(
			targets,
			values,
			calldatas,
			descriptionHash,
		);

		const proposalId = (proposalReceipt?.logs[0] as EventLog).args[0];

		expect(proposalId).to.eq(expectedProposalId);
		console.log(proposalId);

		await expect(
			governor.connect(user1).castVoteWithReason(proposalId, 1, "I like it!")
		).to.be.revertedWithCustomError(
			governor, "GovernorUnexpectedProposalState"
		).withArgs(
			proposalId, 0, "0x0000000000000000000000000000000000000000000000000000000000000002"
		);

		await mine((await governor.votingDelay()) + 1n);

		expect(await governor.state(proposalId)).to.eq(1n);

		const vote1 = await governor.connect(user1).castVoteWithReason(proposalId, 1, "I like it!");
		await vote1.wait();

		const vote2 = await governor.connect(user2).castVoteWithReason(proposalId, 1, "I like it!");
		await vote2.wait();

		expect(await governor.hasVoted(proposalId, user2.address)).to.be.true;

		// await transferWithDecimals(token, user2, user1.address, 5n);

		const propSnapshot = await governor.proposalSnapshot(proposalId);
		console.log(await governor.getVotes(user2.address, propSnapshot));
		console.log(await governor.getVotes(user1.address, propSnapshot));

		await mine((await governor.votingPeriod()) + 1n);

		expect(await governor.state(proposalId)).to.eq(4n);

		const queueTx = await governor.queue(
			targets,
			values,
			calldatas,
			descriptionHash,
		);
		await queueTx.wait();

		await time.increase((await timelock.getMinDelay()) + 1n);

		const executeTx = await governor.connect(user1).execute(targets, values, calldatas, descriptionHash);
		await executeTx.wait();

		expect(await storage.read()).to.eq(42);

		await expect(executeTx).to.changeEtherBalances(
			[storage.target, user2.address],
			[-storageBalance, storageBalance],
		);
	});
});
