const { ethers, upgrades, network } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { verify } = require("./utils/verifier.js")

let { routerAddr, chainSelector, desChainSelector, linkTokenAddr, wETHTokenAddr, nftAddr, crossAddr, wcrossAddr } = require("./utils/cont.config.js")

async function Main() {
    const delay = ms => new Promise(res => setTimeout(res, ms));

// // deploy NFT ------------------------------------------------------------------------
//     const NFT = await ethers.getContractFactory("NFT");
//     const nft = await NFT.deploy();
//     await nft.waitForDeployment();
//     console.log("NFT addr : ", nft.target);
//     await delay(10000)
//     await verify(nft.target, [])

// // deploy Cross ------------------------------------------------------------------------
//     const Cross = await ethers.getContractFactory("Cross");
//     const cross = await Cross.deploy(routerAddr, linkTokenAddr, chainSelector);
//     await cross.waitForDeployment();
//     console.log("Cross : ", cross.target);
//     await delay(10000)
//     await verify(cross.target, [routerAddr, linkTokenAddr, chainSelector])

// mintNFT ------------------------------------------------------------------------
// const nft = await ethers.getContractAt("NFT", nftAddr);
// await nft.safeMint("0xa26FB83C3b27a62146756E88Ec9aDCe234F538B2")
// console.log("NFT minted")

// xTransfer NFT ------------------------------------------------------------------------
    const cross = await ethers.getContractAt("Cross", crossAddr);
    const nft = await ethers.getContractAt("NFT", nftAddr);

    const fee = await cross.getFee(
        desChainSelector,
        "0xa26FB83C3b27a62146756E88Ec9aDCe234F538B2",
        nftAddr,
        8,
        wcrossAddr,
        false
    )
    console.log("transfer fee : ", ethers.formatEther(fee))

    await nft.approve(crossAddr, 8)
    console.log("NFT approved")

    await cross.xTransfer(
        desChainSelector,
        nftAddr,
        8,
        wcrossAddr,
        {value : ethers.parseEther("0.0003")}
    )
    console.log("nft transfered")

}
Main();