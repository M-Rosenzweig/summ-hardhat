const { network } = require("hardhat")
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts(1)
    const { opponent } = await getNamedAccounts(1)
    // const { summFoundation } = await getNamedAccounts(summFoundation)

    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS

    log("----------------------------------------------------")
 
    const SUMMFOUNDATION = [process.env.SUMMFOUNDATION]  

    const arguments = [deployer, opponent,2,3, 18, 20, 4, deployer]
    const SummTerms = await deploy("SummTerms", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: waitBlockConfirmations,
    })
    log("----------------------------------------------------")
    console.log("SummTerms deployed to:", SummTerms.address);
    console.log("deployer:", deployer);
    console.log("opponent:", opponent);
}

module.exports.tags = ["all", "SummTerms"]