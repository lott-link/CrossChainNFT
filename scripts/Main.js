const { ethers, upgrades, network } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { verify } = require("./utils/verifier.js");
const { deployFee } = require("../scripts/utils/gasEstimate.js");

let {
  routerAddr,
  chainSelector,
  desChainSelector,
  linkTokenAddr,
  wETHTokenAddr,
  nftAddr,
  crossAddr,
  wcrossAddr,
} = require("./utils/cont.config.js");

async function Main() {
  const delay = (ms) => new Promise((res) => setTimeout(res, ms));
  // await deployFee("Cross", chainSelector, desChainSelector, routerAddr, linkTokenAddr)

  // // deploy NFT ------------------------------------------------------------------------
  //     const NFT = await ethers.getContractFactory("NFT");
  //     const nft = await NFT.deploy();
  //     await nft.waitForDeployment();
  //     console.log("NFT addr : ", nft.target);
  //     await delay(10000)
  //     await verify(nft.target, [])

  // deploy Cross ------------------------------------------------------------------------
      // const Cross = await ethers.getContractFactory("Polygon_NFT_Bridge");
      // const cross = await Cross.deploy(chainSelector, desChainSelector, routerAddr, linkTokenAddr);
      // await cross.waitForDeployment();
      // console.log("Cross : ", cross.target);
      // await delay(20000)
      await verify("0xCcC8170eB01434Ca514a6f7a5d9ACEB5Ba84DcCc", [chainSelector, desChainSelector, routerAddr, linkTokenAddr])

  // // mintNFT ------------------------------------------------------------------------
  //     const nft = await ethers.getContractAt("NFT", nftAddr);
  //     for(let i = 0; i < 35;  i++) {
  //         await delay(5000)
  //         await nft.safeMint("0xa26FB83C3b27a62146756E88Ec9aDCe234F538B2")
  //         console.log("NFT minted")
  //     }

  // // requestTransferCrossChain NFT ------------------------------------------------------------------------
  // const cross = await ethers.getContractAt("Cross", crossAddr);
  // const nft = await ethers.getContractAt("NFT", nftAddr);

  // const fee = await cross.getFee(
  //   "0xa26FB83C3b27a62146756E88Ec9aDCe234F538B2",
  //   nftAddr,
  //   60,
  //   // wcrossAddr,
  //   false
  // );
  // console.log("transfer fee : ", ethers.formatEther(fee));

  // await nft.approve(crossAddr, 60);
  // console.log("NFT approved");

  // await cross.requestTransferCrossChain(
  //   nftAddr,
  //   "0xa26FB83C3b27a62146756E88Ec9aDCe234F538B2",
  //   60,
  //   // wcrossAddr,
  //   { value: ethers.parseEther("0.0003") }
  // );
  // console.log("nft transfered");
}
Main();
