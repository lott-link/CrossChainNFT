const { ethers, upgrades, network } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { verify } = require("./utils/verifier.js")
const { deployFee } = require("../scripts/utils/gasEstimate.js");

let { routerAddr, chainSelector, desChainSelector, linkTokenAddr, wETHTokenAddr, nftAddr, wcrossAddr, crossAddr } = require("./utils/cont.config.js")

async function Main() {
    const delay = ms => new Promise(res => setTimeout(res, ms));
    // await deployFee("WCross", chainSelector, desChainSelector, routerAddr, linkTokenAddr)
    // await deployFee("ChanceRoom_Sang", factoryAddr)

    // // Main WCross
    // const WCross = await ethers.getContractFactory("WCross");
    // const wcross = await WCross.deploy(chainSelector, desChainSelector, routerAddr, linkTokenAddr);
    // await wcross.waitForDeployment();
    // console.log("WCross : ", wcross.target);

    // await delay(10000)
    // await verify(wcross.target, [chainSelector, desChainSelector, routerAddr, linkTokenAddr])


// // xBack the LockedNFT ------------------------------------------------------------------------------   
//     const wcross = await ethers.getContractAt("WCross", wcrossAddr);

//   const fee = await wcross.getFee(
//     "0xa26FB83C3b27a62146756E88Ec9aDCe234F538B2",
//     0,
//     false
//   );
//   console.log("transfer fee : ", ethers.formatEther(fee));

//   await wcross.requestReleaseLockedToken(
//     0,
//     "0xa26FB83C3b27a62146756E88Ec9aDCe234F538B2",
//     // crossAddr,
//     { value: ethers.parseEther("2.15") }
//   );
//   console.log("nft transfered");
}


Main();