const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const Promise = require("bluebird");

let merkleTree;

let _BMG;
let BMG;


before(async function () {
  _BMG = await ethers.getContractFactory("BaseMintGang");
  BMG = await _BMG.deploy();
});

describe("Tests", function () {
  it("Sets Whitelists", async function () {
  });
});

const getMerkleTree = (addresses) => {
  const leaves = addresses.map((x) => keccak256(x));

  const tree = new MerkleTree(leaves, keccak256, { sort: true });

  return tree;
};
