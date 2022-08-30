const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const Promise = require("bluebird");

const whitelist = require("../whitelists/VFP.json");

let merkleTree;

let _VFP;
let VFP;

let whitelistMinters;
let nonWhitelistedMinters;

before(async function () {
  _VFP = await ethers.getContractFactory("VirtueFoundersPass");
  VFP = await _VFP.deploy();

  allWallets = await ethers.getSigners();
  whitelistMinters = allWallets.slice(0, 501);
  nonWhitelistedMinters = allWallets.slice(501, 550);
});

describe("Tests", function () {
  it("Sets Whitelists", async function () {
    merkleTree = getMerkleTree(whitelistMinters.map((a) => a.address));

    merkleRoot = merkleTree.getHexRoot();

    await VFP.setMerkleRoot(merkleRoot);

    expect(await VFP.merkleRoot()).to.equal(merkleRoot);
  });

  it("Mints 1 per whitelisted address", async function () {
    await Promise.each(whitelistMinters, async (minter, index) => {
      if (index == 500) {
        await expect(
          VFP.connect(minter).mintWhitelist(
            merkleTree.getHexProof(keccak256(whitelistMinters[index].address))
          )
        ).to.be.revertedWith("Max supply reached!");
      } else {
        await VFP.connect(minter).mintWhitelist(
          merkleTree.getHexProof(keccak256(whitelistMinters[index].address))
        );
        expect(parseInt(await VFP.totalSupply())).to.equal(index + 1);
      }
    });

    expect(parseInt(await VFP.totalSupply())).to.equal(500);
  });

  it("Mints 1 per whitelisted address but fails everytime", async function () {
    await Promise.each(whitelistMinters, async (minter, index) => {
      if (index == 500) {
        await expect(
          VFP.connect(minter).mintWhitelist(
            merkleTree.getHexProof(keccak256(whitelistMinters[index].address))
          )
        ).to.be.revertedWith("Max supply reached!");
      } else {
        await expect(
          VFP.connect(minter).mintWhitelist(
            merkleTree.getHexProof(keccak256(whitelistMinters[index].address))
          )
        ).to.be.revertedWith("You already minted!");
      }
    });
  });

  it("Tries to mint from non whitelisted minters", async function () {
    await Promise.each(nonWhitelistedMinters, async (minter, index) => {
      await expect(
        VFP.connect(minter).mintWhitelist(
          merkleTree.getHexProof(keccak256(nonWhitelistedMinters[index].address))
        )
      ).to.be.revertedWith("MerkleWhitelist: Caller is not whitelisted");
    });
  });
});

const getMerkleTree = (addresses) => {
  const leaves = addresses.map((x) => keccak256(x));

  const tree = new MerkleTree(leaves, keccak256, { sort: true });

  return tree;
};
