const { network } = require("hardhat")
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts(1)


    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS

    log("----------------------------------------------------")
 
    const SummTermsAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"

    const arguments = [SummTermsAddress]
    const FirmOffers = await deploy("FirmOffers", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: waitBlockConfirmations,
    })
    log("----------------------------------------------------")
    console.log("FirmOffers deployed to:", FirmOffers.address);
}

module.exports.tags = ["all", "FirmOffers"]