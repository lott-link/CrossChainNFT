const { ethers, upgrades, network } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { verify } = require("./utils/verifier.js")

let { routerAddr, desChainSelector, linkTokenAddr, wETHTokenAddr } = require("./utils/cont.config.js")

async function deploy() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

    // deploy CCIP
    const CCIP = await ethers.getContractFactory("CCIP");
    const ccip = await CCIP.deploy(routerAddr, linkTokenAddr);
    await ccip.waitForDeployment();
    console.log("CCIP : ", ccip.target);

    await delay(10000)
    await verify(ccip.address, [routerAddr, linkTokenAddr])
}
deploy();