const { network } = require("hardhat");

const zero_address = "0x0000000000000000000000000000000000000000"

let routerAddr = zero_address
let desChainSelector = 0
let linkTokenAddr = zero_address
let wETHTokenAddr = zero_address
let ccipAddr = zero_address

  if(network.config.chainId == 11155111) {

    routerAddr = "0xD0daae2231E9CB96b94C8512223533293C3693Bf"
    desChainSelector = "12532609583862916517" // mumbai chain selector
    linkTokenAddr = "0x779877A7B0D9E8603169DdbD7836e478b4624789"
    wETHTokenAddr = "0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534"
    ccipAddr = "0xd6fecB12ae2c23069369Cc62f9470176a648b59a"

  } else if(network.config.chainId == 80001) {

    routerAddr = "0x70499c328e1E2a3c41108bd3730F6670a44595D1"
    desChainSelector = "16015286601757825753" // sepolia chain selector
    linkTokenAddr = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"
    wETHTokenAddr = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889" // wMATIC
    ccipAddr = "0xd6fecB12ae2c23069369Cc62f9470176a648b59a"

  }


module.exports = {
  routerAddr,
  desChainSelector,
  linkTokenAddr,
  wETHTokenAddr,
  ccipAddr
  
}