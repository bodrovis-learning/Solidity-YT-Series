// Based on https://github.com/mudgen/diamond-3-hardhat/blob/main/scripts/deploy.js

import { ethers } from "hardhat";
import { FacetCutAction, getSelectors } from "./lib/diamond";

async function deployFacet(FacetName: string) {
	const Facet = await ethers.getContractFactory(FacetName);
	const facet = await Facet.deploy();
	await facet.waitForDeployment();
	const selectors = getSelectors(facet).selectors;

	console.log(
		`${FacetName} deployed at: ${facet.target}, with selectors: ${selectors}`,
	);

	return {
		facetAddress: facet.target,
		action: FacetCutAction.Add,
		functionSelectors: selectors,
	};
}

export async function deployDiamond() {
	console.log(
		`Deploying contracts using FacetCutAction: ${FacetCutAction.Add}`,
	);

	const [deployer] = await ethers.getSigners();
	console.log(`Deployer address: ${deployer.address}`);

	// Deploy DiamondCutFacet
	const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
	const diamondCutFacet = await DiamondCutFacet.deploy();
	await diamondCutFacet.waitForDeployment();
	console.log(`DiamondCutFacet deployed at: ${diamondCutFacet.target}`);

	// Deploy Diamond
	const Diamond = await ethers.getContractFactory("Diamond");
	const diamond = await Diamond.deploy(
		deployer.address,
		diamondCutFacet.target,
	);
	await diamond.waitForDeployment();
	console.log(`Diamond deployed at: ${diamond.target}`);

	// Deploy DiamondInit
	const DiamondInit = await ethers.getContractFactory("DiamondInit");
	const diamondInit = await DiamondInit.deploy();
	await diamondInit.waitForDeployment();
	console.log(`DiamondInit deployed at: ${diamondInit.target}`);

	// Deploy facets
	console.log("Deploying facets...");
	const FacetNames = ["DiamondLoupeFacet", "OwnershipFacet"];
	const cut = await Promise.all(
		FacetNames.map((FacetName) => deployFacet(FacetName)),
	);

	// Upgrade diamond with facets
	console.log("Executing diamond cut...");
	const diamondCut = await ethers.getContractAt("IDiamondCut", diamond.target);
	const functionCall = diamondInit.interface.encodeFunctionData("init");

	const tx = await diamondCut.diamondCut(cut, diamondInit.target, functionCall);
	console.log("Diamond cut transaction hash:", tx.hash);

	const receipt = await tx.wait();
	if (!receipt?.status) {
		throw new Error(`Diamond upgrade failed: ${tx.hash}`);
	}

	console.log("Diamond cut completed successfully");
	return diamond.target;
}

async function main() {
	try {
		await deployDiamond();
	} catch (error) {
		console.error(error);
		process.exitCode = 1;
	}
}

main();
