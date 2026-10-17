const hre = require("hardhat");

async function main() {
  const Capsule = await hre.ethers.getContractFactory("AetherTimeCapsule");
  const capsule = await Capsule.deploy();
  await capsule.deployed();
  console.log("Time Capsule deployed to:", capsule.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
