const { ethers, waffle } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const Promise = require("bluebird");
const fs = require("fs");
const path = require("path");
const addresses = require("../whitelists/whitelistAddresses.json");

async function main() {
  _VirtueFoundersPass = await ethers.getContractFactory("VirtueFoundersPass");
  VirtueFoundersPass = await _VirtueFoundersPass.deploy();

  console.log(
    `Deployed VirtueFoundersPass at address: ${VirtueFoundersPass.address}`
  );

  const leaves = addresses.map((x) => keccak256(x));
  const tree = new MerkleTree(leaves, keccak256, { sort: true });
  const root = tree.getHexRoot();

  await VirtueFoundersPass.setMerkleRoot(root);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
