// Based on https://github.com/mudgen/diamond-3-hardhat/blob/main/scripts/libraries/diamond.js

import type { BaseContract } from "ethers";
import { ethers } from "hardhat";

export enum FacetCutAction {
	Add = 0,
	Replace = 1,
	Remove = 2,
}

interface SelectorSet {
	selectors: string[];
	contract: BaseContract;
	remove: (functionNames: string[]) => string[];
	get: (functionNames: string[]) => string[];
}

interface Facet {
	facetAddress: string;
}

// Get function selectors from ABI
export function getSelectors(contract: BaseContract): SelectorSet {
	const selectors: string[] = [];

	// Iterate over contract functions and get their selectors
	contract.interface.forEachFunction((f) => {
		if (
			f.name !== "init" &&
			(f.inputs.length === 0 || f.inputs[0].type !== "bytes")
		) {
			const sel = contract.interface.getFunction(f.name)?.selector;
			if (sel) {
				selectors.push(sel);
			}
		}
	});

	return {
		selectors,
		contract,
		remove: remove.bind({ selectors, contract }),
		get: get.bind({ selectors, contract }),
	};
}

// Remove selectors based on an array of function names
function remove(
	this: { selectors: string[]; contract: BaseContract },
	functionNames: string[],
): string[] {
	const { selectors, contract } = this;
	return selectors.filter((v) => {
		return !functionNames.some(
			(name) => v === contract.interface.getFunction(name)?.selector,
		);
	});
}

// Get specific selectors from the selectors array based on function names
function get(
	this: { selectors: string[]; contract: BaseContract },
	functionNames: string[],
): string[] {
	const { selectors, contract } = this;
	return selectors.filter((v) => {
		return functionNames.some(
			(name) => v === contract.interface.getFunction(name)?.selector,
		);
	});
}

// Remove selectors using an array of function signatures
export function removeSelectors(
	selectors: string[],
	signatures: string[],
): string[] {
	// Create an interface from the signatures (assuming signatures are valid function declarations)
	const iface = new ethers.Interface(signatures.map((v) => `function ${v}`));

	// Map signatures to their selectors, safely handling missing selectors
	const removeSelectors = signatures.map((v) => {
		const selector = iface.getFunction(v)?.selector;
		if (!selector) {
			throw new Error(`Selector for function ${v} not found.`);
		}
		return selector;
	});

	// Filter out the selectors to be removed
	return selectors.filter((v) => !removeSelectors.includes(v));
}

// Find a particular address position in the facets array
export function findAddressPositionInFacets(
	facetAddress: string,
	facets: Facet[],
): number | undefined {
	return facets.findIndex((facet) => facet.facetAddress === facetAddress);
}
