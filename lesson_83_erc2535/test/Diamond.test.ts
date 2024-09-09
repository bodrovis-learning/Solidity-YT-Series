import { FacetCutAction, getSelectors } from "../scripts/lib/diamond";

import type { ContractTransactionResponse } from "ethers";
import { deployDiamond } from "../scripts/deploy";
import type { DiamondCutFacet, DiamondLoupeFacet } from "../typechain-types";
import { ethers, expect, loadFixture } from "./setup";

describe("DiamondTest", async () => {
	async function deploy() {
		const diamondAddress = await deployDiamond();

		const diamondCutFacet = await ethers.getContractAt(
			"DiamondCutFacet",
			diamondAddress,
		);

		const diamondLoupeFacet = await ethers.getContractAt(
			"DiamondLoupeFacet",
			diamondAddress,
		);

		const ownershipFacet = await ethers.getContractAt(
			"OwnershipFacet",
			diamondAddress,
		);

		return {
			diamondAddress,
			diamondCutFacet,
			diamondLoupeFacet,
			ownershipFacet,
		};
	}

	async function getFacetAddresses(
		diamondLoupeFacet: DiamondLoupeFacet,
	): Promise<string[]> {
		const addresses = [];

		for (const address of await diamondLoupeFacet.facetAddresses()) {
			addresses.push(address);
		}

		return addresses;
	}

	async function diamondCut(
		diamondCutFacet: DiamondCutFacet,
		facetAddress: string,
		selectors: string[],
	): Promise<ContractTransactionResponse> {
		return diamondCutFacet.diamondCut(
			[
				{
					facetAddress: facetAddress,
					action: FacetCutAction.Add,
					functionSelectors: selectors,
				},
			],
			ethers.ZeroAddress,
			"0x",
			{ gasLimit: 800000 },
		);
	}

	it("should have three facets -- call to facetAddresses function", async () => {
		const { diamondLoupeFacet } = await loadFixture(deploy);
		const addresses = await getFacetAddresses(diamondLoupeFacet);
		expect(addresses.length).to.eq(3);
	});

	it("facets should have the right function selectors -- call to facetFunctionSelectors function", async () => {
		const { diamondCutFacet, diamondLoupeFacet, ownershipFacet } =
			await loadFixture(deploy);

		const addresses = await getFacetAddresses(diamondLoupeFacet);

		// Test diamondCutFacet selectors
		let selectors = getSelectors(diamondCutFacet).selectors;
		let result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0]);
		expect([...result]).to.have.members(selectors);

		// Test diamondLoupeFacet selectors
		selectors = getSelectors(diamondLoupeFacet).selectors;
		result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1]);
		expect([...result]).to.have.members(selectors);

		// Test ownershipFacet selectors
		selectors = getSelectors(ownershipFacet).selectors;
		result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2]);
		expect([...result]).to.have.members(selectors);
	});

	it("selectors should be associated to facets correctly -- multiple calls to facetAddress function", async () => {
		const { diamondLoupeFacet } = await loadFixture(deploy);
		const addresses = await getFacetAddresses(diamondLoupeFacet);

		expect(addresses[0]).to.equal(
			await diamondLoupeFacet.facetAddress("0x1f931c1c"),
		);
		expect(addresses[1]).to.equal(
			await diamondLoupeFacet.facetAddress("0xcdffacc6"),
		);
		expect(addresses[1]).to.equal(
			await diamondLoupeFacet.facetAddress("0x01ffc9a7"),
		);
		expect(addresses[2]).to.equal(
			await diamondLoupeFacet.facetAddress("0xf2fde38b"),
		);
	});

	it("should add test1 and test2 functions", async () => {
		const { diamondAddress, diamondCutFacet, diamondLoupeFacet } =
			await loadFixture(deploy);

		const Test1Facet = await ethers.getContractFactory("Test1Facet");
		const test1Facet = await Test1Facet.deploy();
		await test1Facet.waitForDeployment();

		const addresses = await getFacetAddresses(diamondLoupeFacet);
		const test1FacetAddr = await test1Facet.getAddress();
		addresses.push(test1FacetAddr);

		// Get the selectors and remove `supportsInterface(bytes4)`
		const selectors = getSelectors(test1Facet).remove([
			"supportsInterface(bytes4)",
		]);

		const tx = await diamondCut(diamondCutFacet, test1FacetAddr, selectors);
		const receipt = await tx.wait();

		if (!receipt?.status) {
			throw Error(`Diamond upgrade failed: ${tx.hash}`);
		}

		// Validate the function selectors after diamond cut
		const result =
			await diamondLoupeFacet.facetFunctionSelectors(test1FacetAddr);
		expect([...result]).to.have.members(selectors);

		// Deploy Test2Facet
		const Test2Facet = await ethers.getContractFactory("Test2Facet");
		const test2Facet = await Test2Facet.deploy();
		await test2Facet.waitForDeployment();
		const test2FacetAddr = await test2Facet.getAddress();

		console.log(`Test2Facet deployed at: ${test2FacetAddr}`);

		addresses.push(test2FacetAddr); // Add Test2Facet's address to the list

		// Get selectors from Test2Facet
		const selectorsTest2 = getSelectors(test2Facet).selectors;

		const tx2 = await diamondCut(
			diamondCutFacet,
			test2FacetAddr,
			selectorsTest2,
		);
		const receipt2 = await tx2.wait();

		// Ensure the transaction was successful
		if (!receipt2?.status) {
			throw new Error(`Diamond upgrade failed: ${tx.hash}`);
		}

		// Validate that selectors were added
		const result2 =
			await diamondLoupeFacet.facetFunctionSelectors(test2FacetAddr);
		expect([...result2]).to.have.members(selectorsTest2);

		// Reconnect with Test2Facet and invoke the function
		const test2FacetReconn = await ethers.getContractAt(
			"Test2Facet",
			diamondAddress,
		);
		const func11Receipt = await test2FacetReconn.test2Func11();
		await expect(func11Receipt).to.emit(test2FacetReconn, "Test2Event11");

		// Reconnect and invoke a test function from Test1Facet
		const test1FacetReconn = await ethers.getContractAt(
			"Test1Facet",
			diamondAddress,
		);
		const func10Receipt = await test1FacetReconn.test1Func10();
		await expect(func10Receipt).to.emit(test1FacetReconn, "TestEvent10");
	});

	it("should remove some test1 functions", async () => {
		const { diamondCutFacet, diamondLoupeFacet } = await loadFixture(deploy);

		// Deploy Test1Facet
		const Test1Facet = await ethers.getContractFactory("Test1Facet");
		const test1Facet = await Test1Facet.deploy();
		await test1Facet.waitForDeployment();

		const addresses = await getFacetAddresses(diamondLoupeFacet);
		const test1FacetAddr = await test1Facet.getAddress();
		addresses.push(test1FacetAddr);

		// Selectors for the initial diamond cut (without 'supportsInterface(bytes4)')
		const selectors = getSelectors(test1Facet).remove([
			"supportsInterface(bytes4)",
		]);
		console.log("Initial selectors to add:", selectors);

		// Add Test1Facet selectors
		const tx = await diamondCut(diamondCutFacet, test1FacetAddr, selectors);
		const receipt = await tx.wait();
		if (!receipt?.status) {
			throw new Error(`Diamond upgrade failed: ${tx.hash}`);
		}

		// Selectors to remove (keeping some functions)
		const functionsToKeep = ["test1Func2()", "test1Func11()", "test1Func12()"];
		const selectorsToRemove = getSelectors(test1Facet).remove(functionsToKeep);

		console.log("Selectors to remove:", selectorsToRemove);

		// Remove Test1Facet selectors
		const tx2 = await diamondCutFacet.diamondCut(
			[
				{
					facetAddress: ethers.ZeroAddress,
					action: FacetCutAction.Remove,
					functionSelectors: selectorsToRemove,
				},
			],
			ethers.ZeroAddress,
			"0x",
			{ gasLimit: 800000 },
		);

		const receipt2 = await tx2.wait();
		if (!receipt2?.status) {
			throw new Error(`Diamond upgrade failed: ${tx2.hash}`);
		}

		// Validate the remaining functions
		const result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3]);
		console.log("Remain:", result);
		expect([...result]).to.have.members(
			getSelectors(test1Facet).get(functionsToKeep),
		);
	});
});
