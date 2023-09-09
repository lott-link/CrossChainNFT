const { ethers, upgrades, network } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { verify } = require("./utils/verifier.js")

let { routerAddr, chainSelector, desChainSelector, linkTokenAddr, wETHTokenAddr, nftAddr } = require("./utils/cont.config.js")

// ye contract e clonable upgradeable darim baraye wNFT.
// 
async function Main() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

    // Main WCross
    const WCross = await ethers.getContractFactory("WCross");
    const wcross = await WCross.deploy(chainSelector, routerAddr, linkTokenAddr);
    await wcross.waitForDeployment();
    console.log("WCross : ", wcross.target);

    await delay(10000)
    await verify(wcross.target, [chainSelector, routerAddr, linkTokenAddr])
}
Main();