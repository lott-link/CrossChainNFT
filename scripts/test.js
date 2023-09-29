// /* global describe it before ethers */

// const { time } = require("@nomicfoundation/hardhat-network-helpers");
// const { assert, expect } = require("chai");
// const { callFee } = require("../scripts/utils/gasEstimate.js");

// describe("nft test", async function () {
//   const hour = 60 * 60;
//   let zero_address;
//   let deployer,
//     user1,
//     user2,
//     user3,
//     user4,
//     user5,
//     user6,
//     user7,
//     user8,
//     user9,
//     user10;
//   let nft;
//   let cross;
//   let wcross;
//   let sender;

//   before(async function () {
//     zero_address = "0x0000000000000000000000000000000000000000";
//     const accounts = await ethers.getSigners();
//     [
//       deployer,
//       user1,
//       user2,
//       user3,
//       user4,
//       user5,
//       user6,
//       user7,
//       user8,
//       user9,
//       user10,
//     ] = accounts;
//   });

//   it("should deploy NFT", async () => {
//     const NFT = await ethers.getContractFactory("NFT");
//     nft = await NFT.deploy();
//     await nft.waitForDeployment();
//     console.log("NFT addr : ", nft.target);
//   });

//   // it('should deploy Cross', async () => {
//   //     const Cross = await ethers.getContractFactory("Cross");
//   //     // cross = await Cross.deploy(zero_address, zero_address);
//   //     // await cross.waitForDeployment();
//   //     // console.log("Cross addr : ", cross.target);
//   // })

//   // it('should xtransfer', async () => {
//   //     await nft.safeMint(user1.address)
//   //     await nft.connect(user1).approve(cross.target, 0)
//   //     await cross.connect(user1).requestTransferCrossChain(
//   //         nft.target,
//   //         0,
//   //         0,
//   //         0
//   //     );
//   //     // console.log("Cross addr : ", cross.target);
//   // })

//   it("should deploy WCross", async () => {
//     const Sender = await ethers.getContractFactory("Sender");
//     sender = await Sender.deploy();
//     await sender.waitForDeployment();
//     console.log("Sender addr : ", sender.target);
//     wcross = await ethers.getContractAt("WCross", await sender.wcross());
//     console.log("wcross addr : ", wcross.target);
//   });

//   it("should ccip receive", async () => {
//     // let message = [
//     //     "0x7ba79506b8b60cf33d8792bb80b0ab24ee50e2583d19de0e90b0a80fdcdd9ccb", // MessageId corresponding to ccipSend on source.
//     //     "16015286601757825753", // Source chain selector.
//     //     "0x0000000000000000000000009fE46736679d2D9a65F0992F2272dE9f3c7fa6e0", // abi.decode(sender) if coming from an EVM chain.
//     //     "0x322ae084000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb922660000000000000000000000004b20993bc481177ec7e8f571cecae8a9e22c02db000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000034e4654000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034e46540000000000000000000000000000000000000000000000000000000000",// payload sent in original message.
//     //     [] // Tokens and their amounts in their destination chain representation.
//     // ]
//     // await wcross.createWContract(
//     //     "16015286601757825753",
//     //     "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
//     //     "NFT",
//     //     "NFT"
//     // )
//     await sender.send();
//     //   await callFee(deployer.address, wcross, "ccipReceive", message)
//     // await wcross.ccipReceive(message)
//     const wcontracts = await wcross.wContracts();
//     const wCont = wcontracts[0][2];
//     console.log(wCont);
//     const wCo = await ethers.getContractAt("WNFT", wCont);
//     console.log(await wCo.balanceOf(deployer.address));
//     // console.log(deployer.address)
//   });
// });
