const { network } = require("hardhat")
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
     // these two objects come from the hre the Hardhat Runtime envirement. (i think thats what it stands for.. could be slightly off.)
    // getNamedAccounts allows us to access the signer / accounts[0] the account we are using to deploy the stuff. gets it from the HARDHAT CONFIG FILE 
    // deployments lets us actually deploy and log (plus other stuff but that is what we are doing here..)
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    // const chainId = network.config.chainId
    const waitBlockConfirmations = developmentChains.includes(network.name) // if its a testnet than we should do 6 / couple as stipulated in our helper-hardhat-config
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS

    log("----------------------------------------------------") // letting us know we are starting the magic. 
    const arguments = [process.env.SUMMFOUNDATION]  
    const SummFactory = await deploy("SummFactory", { //  - hardhat is smart enough to look into contracts for a contract with this name and it takes care of buisness
        from: deployer, // as we layed out in hardhat config for the network we are on. 
        args: arguments, // in this case the constructor doesnt need anything
        log: true, // we allow the log functionality
        waitConfirmations: waitBlockConfirmations, // how long to wait before continuing with script and verifiying
    })

    log(
        `SummFactory deployed to: ${SummFactory.address} on ${network.name} network.`
    )
    log(
        `deployer: ${deployer}`
    )

    // Verify the deployment (we not on development chains and we have a etherscan API then verify. )
    // if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    //     log("Verifying...")
    //     await verify(SummFactory.address, arguments)
    // }
    // log("----------------------------------------------------")
    // console.log("SummFactory deployed to:", SummFactory.address); 
}

module.exports.tags = ["all", "summFactory"] // when giving command in terminal to deploy can use tags to only deploy certain ones..
