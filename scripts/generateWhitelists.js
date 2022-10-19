const { ethers } = require("hardhat");
const Promise = require("bluebird");

const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const fs = require("fs");
const path = require("path");

const generateMerkleTree = (addresses, name) => {
  const leaves = addresses.map((x) => keccak256(x));

  const merkleTree = new MerkleTree(leaves, keccak256, { sort: true });

  const root = merkleTree.getHexRoot();

  const proofs = leaves.map((hash) => merkleTree.getHexProof(hash));

  if (name != "") {
    fs.writeFileSync(
      path.join(__dirname, `../whitelists/${name}.json`),
      JSON.stringify({ root, proofs }, undefined, 4)
    );
  }
  return {root, proofs};
};



module.exports.generateMerkleTree=generateMerkleTree;