const { ethers, waffle } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const Promise = require("bluebird");
const fs = require("fs");
const path = require("path");

const { root } = require("../whitelists/whitelist.json");

async function main() {
  _BaseMintGang = await ethers.getContractFactory("BaseMintGang");
  BaseMintGang = await _BaseMintGang.deploy();

  console.log(
    `Deployed BaseMintGang at address: ${BaseMintGang.address}`
  );

  //await BaseMintGang.setMerkleRoot(root);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
