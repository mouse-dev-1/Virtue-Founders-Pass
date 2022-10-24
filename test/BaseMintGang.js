const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const Promise = require("bluebird");
const { generateMerkleTree } = require("../scripts/generateWhitelists");

var owner;

provider = waffle.provider;

const firstSaleStartTime = 1666710000;
const secondSaleStartTime = 1666713600;
const thirdSaleStartTime = 1666800000;

var stakeTimes = {};

before(async function () {
  _BMG = await ethers.getContractFactory("BaseMintGang");
  BaseMintGang = await _BMG.deploy();

  minters = await ethers.getSigners();
  owner = minters[0];

  //Whitelist
  whitelistMinters = minters.slice(0, 250);
  whitelistTree = generateMerkleTree(
    whitelistMinters.map((a) => a.address),
    "whitelist"
  );
  await BaseMintGang.setWhitelistMerkleRoot(whitelistTree.root, 0);

  //Allowlist
  allowlistMinters = minters.slice(500, 800);
  allowlistTree = generateMerkleTree(
    allowlistMinters.map((a) => a.address),
    "allowlist"
  );

  await BaseMintGang.setWhitelistMerkleRoot(allowlistTree.root, 1);

  //Public
  publicMinters = minters.slice(800, 847);

  //Airdrop
  virtueHolders = minters.slice(847, 1147);
});

const mostRecentBlockTime = async () => {
  return (
    await ethers.provider.getBlock(await ethers.provider.getBlockNumber())
  ).timestamp;
};

const setCurrentBlockTime = async (newTimestamp) => {
  await network.provider.send("evm_setNextBlockTimestamp", [newTimestamp]);
  await network.provider.send("evm_mine");
};

const sendEth = (amt) => {
  return { value: ethers.utils.parseEther(amt) };
};

const sendWei = (amt) => {
  return { value: amt };
};

describe("Tests", async function () {
  /*it("Tests whitelist mint.", async function () {
    await setCurrentBlockTime(firstSaleStartTime);
    await Promise.map(whitelistMinters, async (whitelistMinter, index) => {
      return BaseMintGang.connect(whitelistMinter).mintWhitelist(
        8,
        whitelistTree.proofs[index],
        sendEth("0.5628")
      );
    });

    expect(await BaseMintGang.totalSupply()).to.equal(whitelistMinters.length);
  });

  it("Tests allowlist mint.", async function () {
    await setCurrentBlockTime(secondSaleStartTime);
    await Promise.map(allowlistMinters, async (allowlistMinter, index) => {
      return BaseMintGang.connect(allowlistMinter).mintAllowlist(
        8,
        allowlistTree.proofs[index],
        sendEth("0.5628")
      );
    });

    expect(await BaseMintGang.totalSupply()).to.equal(
      whitelistMinters.length * 8 + allowlistMinters.length * 8
    );
  });*/

  it("Tests public mint.", async function () {
    await setCurrentBlockTime(thirdSaleStartTime);
    await Promise.map(publicMinters, async (publicMinter, index) => {
      return BaseMintGang.connect(publicMinter).mintPublic(
        4,
        sendEth("0.1876")
      );
    });

    //expect(await BaseMintGang.totalSupply()).to.equal(
    //  whitelistMinters.length * 8 +
    //    allowlistMinters.length * 8 +
    //    publicMinters.length * 4
    //);
  });
  /*
  it("airdrops to virtue holders.", async function () {
    await BaseMintGang.connect(owner).airdropForVirtuePassHolders(
      virtueHolders.map((a) => a.address)
    );

    expect(await BaseMintGang.totalSupply()).to.equal(
      whitelistMinters.length * 8 +
        allowlistMinters.length * 8 +
        publicMinters.length * 4 +
        virtueHolders.length * 1
    );
  });

  it("Reveals collection", async function () {
    //Reveal
    await BaseMintGang.setBaseURI("https://basemintgang.api/");
    await BaseMintGang.setRevealData("unrevealed", true);
  });*/

  it("Stakes 4 tokens and expects them to be untransferrable", async function () {
    await Promise.each(publicMinters, async (publicMinter) => {
      const walletOfOwner = await BaseMintGang.walletOfOwner(
        publicMinter.address
      );
      const tokens = walletOfOwner.map((a) => a.tokenId);

      await BaseMintGang.connect(publicMinter).stake(tokens);

      stakeTimes[publicMinter.address] = await mostRecentBlockTime();

      await expect(
        BaseMintGang.connect(publicMinter).transferFrom(
          publicMinter.address,
          allowlistMinters[0].address,
          tokens[1]
        )
      ).to.be.revertedWith("Token Not Currently Transferrable");
    });
  });

  it("Checks stake status after a lot of seconds and ensures its correct.", async function () {
    await setCurrentBlockTime((await mostRecentBlockTime()) + 100000);

    await Promise.each(publicMinters, async (publicMinter) => {
      const walletOfOwner = await BaseMintGang.walletOfOwner(
        publicMinter.address
      );

      console.log(
        `Token ${walletOfOwner[2].tokenId} owned by ${
          publicMinter.address
        }, original stake stamp ${stakeTimes[publicMinter.address]} ---`
      );
      expect(
        parseInt(await mostRecentBlockTime()) -
          parseInt(walletOfOwner[2]._tokenStakeDetails.currentStakeTimestamp)
      ).to.equal(
        parseInt(walletOfOwner[2]._tokenStakeDetails.totalStakeTimeAccrued)
      );
    });
  });

  it("Unstakes.", async function () {
    await setCurrentBlockTime((await mostRecentBlockTime()) + 100000);

    await Promise.each(publicMinters, async (publicMinter) => {
      const walletOfOwner = await BaseMintGang.walletOfOwner(
        publicMinter.address
      );
      const tokens = walletOfOwner.map((a) => a.tokenId);

      await BaseMintGang.connect(publicMinter).unstake(tokens);

      stakeTimes[publicMinter.address] = await mostRecentBlockTime();

      await BaseMintGang.connect(publicMinter).transferFrom(
        publicMinter.address,
        allowlistMinters[0].address,
        tokens[1]
      )
    });
  });
});
