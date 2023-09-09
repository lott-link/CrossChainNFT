/* global describe it before ethers */

const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { assert, expect } = require('chai')


describe('nft test', async function () {

    const hour = 60 * 60;
    let zero_address
    let deployer, user1, user2, user3, user4, user5, user6, user7, user8, user9, user10
    let nft
    let cross

    before(async function () {
        zero_address = "0x0000000000000000000000000000000000000000"
        const accounts = await ethers.getSigners();
        [deployer, user1, user2, user3, user4, user5, user6, user7, user8, user9, user10] = accounts
    }) 

    it('should deploy NFT', async () => {
        const NFT = await ethers.getContractFactory("NFT");
        nft = await NFT.deploy();
        await nft.waitForDeployment();
        console.log("NFT addr : ", nft.target);
    })

    it('should deploy Cross', async () => {
        const Cross = await ethers.getContractFactory("Cross");
        cross = await Cross.deploy();
        await cross.waitForDeployment();
        console.log("Cross addr : ", cross.target);
    })

    it('should xtransfer', async () => {
        await nft.safeMint(user1.address)
        await nft.connect(user1).approve(cross.target, 0)
        await cross.connect(user1).xTransfer(
            nft.target,
            0,
            0,
            0
        );
        // console.log("Cross addr : ", cross.target);
    })
    
    
})