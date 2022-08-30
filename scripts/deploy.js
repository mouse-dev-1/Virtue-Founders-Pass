const { ethers, waffle } = require("hardhat");

async function main() {
  _VirtueFoundersPass = await ethers.getContractFactory("VirtueFoundersPass");
  VirtueFoundersPass = await _VirtueFoundersPass.deploy();

  console.log(
    `Deployed VirtueFoundersPass at address: ${VirtueFoundersPass.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
