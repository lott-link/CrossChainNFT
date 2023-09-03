const { ethers, network } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { verify } = require("./utils/verifier.js")
let { routerAddr, desChainSelector, linkTokenAddr, wETHTokenAddr, ccipAddr } = require("./utils/cont.config.js")

async function deploySang() {
  const delay = ms => new Promise(res => setTimeout(res, ms));

  const text = "hello from chainId:" + network.config.chainId.toString()
 
  const ccip = await ethers.getContractAt("CCIP", ccipAddr)

  console.log(await ccip.getLastReceivedMessageDetails())
}
deploySang();