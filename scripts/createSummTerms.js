const { ethers, network } = require("hardhat");
const { moveBlocks } = require("../utils/move-blocks");
// import contract abi from artifacts
const SummFactoryAbi = require("../artifacts/contracts/SummFactory.sol/SummFactory.json");
const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

async function createSummTerms() {
  console.log("lets create summ terms!");
//   const { deployer } = await getNamedAccounts();
//   const signer = await ethers.provider.getSigner(deployer);
const signer = 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6; 

  let arguments = {
    _opponent: "0xd8e22Da698F389F5C916B29aBc3a147d1A475E48",
    _softOffers: 2,
    _firmOffers: 3,
    _softRange: 18,
    _firmRange: 20,
    _penaltyPercent: 5,
  };

  const SummFactory = await ethers.Contract(contractAddress, SummFactoryAbi, signer);
  const tx = await SummFactory.createSummTerms(arguments);
  await tx.wait(1);
  console.log("Summ Terms created");
  if (network.config.chainId === "31337") {
    await moveBlocks(2, (sleepAmount = 1000));
  }
}

createSummTerms()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
