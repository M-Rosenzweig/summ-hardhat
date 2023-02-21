const { network } = require("hardhat");
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();
  
    const waitBlockConfirmations = developmentChains.includes(network.name)
      ? 1
      : VERIFICATION_BLOCK_CONFIRMATIONS;
  
    log("----------------------------------------------------");
  
    const SummTermsAddress = "0xB581C9264f59BF0289fA76D61B2D0746dCE3C30D";
  
    const arguments = [SummTermsAddress];
    const Summ = await deploy("Summ", {
      from: deployer,
      args: arguments,
      log: true,
      waitConfirmations: waitBlockConfirmations,
      // gas: 5000000,
    });
    log("----------------------------------------------------");
    console.log("Summ deployed to:", Summ.address);
    console.log("deployer:", deployer);
  };
  
  module.exports.tags = ["all", "Summ"];
  