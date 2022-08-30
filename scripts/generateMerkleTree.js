const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const Promise = require("bluebird");
const fs = require('fs');
const path = require("path");
const addresses = require("../whitelists/whitelistAddresses.json");


const leaves = addresses.map((x) => keccak256(x));
const tree = new MerkleTree(leaves, keccak256, { sort: true });
const root = tree.getHexRoot();
const proofs = {};

addresses.forEach((address) =>{
    const leaf = keccak256(address);
    const proof = tree.getHexProof(leaf);
    proofs[address] = proof;
});

fs.writeFileSync(path.join(__dirname, "../whitelists/whitelist.json"), JSON.stringify({root, proofs}, undefined, 4));