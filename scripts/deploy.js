const { ethers, upgrades, network } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { verify } = require("./utils/verifier.js")

let { routerAddr, desChainSelector, linkTokenAddr, wETHTokenAddr } = require("./utils/cont.config.js")

// user az ethereum pool mide NFTsho mifreste be polygon.
// ma az in user pooli nemigirim. be dardemoon ham nemikhore chon pairToken e ma rooye polygone.
// az in taraf ke user khast NFTsho bargardoone, azash pool migirim. be chi? matic ya link.
// badesh chikar mikonim? matic ya link ro 30% esho mifrestim be dapp, 70% esho mifrestim be uniswap.
// pooli ke mire be uniswap, tabdil mishe be lottToken barmigarde be contract.
// badesh ma harchi lottToken darim ro burn mikonim.
// esme layer2 NFT contract ro ham mizarim ETH_POL_NFT_Bridge
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