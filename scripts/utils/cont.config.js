const { network } = require("hardhat");

const zero_address = "0x0000000000000000000000000000000000000000"

let nftAddr = zero_address
let routerAddr = zero_address
let desChainSelector = 0
let chainSelector = 0
let linkTokenAddr = zero_address
let wETHTokenAddr = zero_address
let ccipAddr = zero_address
let crossAddr = "0xc8cA43AbA32EbF04b3a650Af2762f229681BAc4a"
let wcrossAddr = "0xc8cA43AbA32EbF04b3a650Af2762f229681BAc4a"

  if(network.config.chainId == 11155111) {

    nftAddr = "0xD6995e1e84A95458937cD020Ab64387758Cfc908"
    routerAddr = "0xD0daae2231E9CB96b94C8512223533293C3693Bf"
    chainSelector = "16015286601757825753" // sepolia chain selector
    desChainSelector = "12532609583862916517" // mumbai chain selector
    linkTokenAddr = "0x779877A7B0D9E8603169DdbD7836e478b4624789"
    wETHTokenAddr = "0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534"
    ccipAddr = "0xd6fecB12ae2c23069369Cc62f9470176a648b59a"

  } else if(network.config.chainId == 80001) {

    routerAddr = "0x70499c328e1E2a3c41108bd3730F6670a44595D1"
    chainSelector = "12532609583862916517" // mumbai chain selector
    desChainSelector = "16015286601757825753" // sepolia chain selector
    linkTokenAddr = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"
    wETHTokenAddr = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889" // wMATIC
    ccipAddr = "0xd6fecB12ae2c23069369Cc62f9470176a648b59a"

  } else {

  routerAddr = "0x70499c328e1E2a3c41108bd3730F6670a44595D1"
  chainSelector = "12532609583862916517" // mumbai chain selector
  desChainSelector = "16015286601757825753" // sepolia chain selector
  linkTokenAddr = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"
  wETHTokenAddr = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889" // wMATIC
  ccipAddr = "0xd6fecB12ae2c23069369Cc62f9470176a648b59a"

}


module.exports = {
  nftAddr,
  routerAddr,
  desChainSelector,
  chainSelector,
  linkTokenAddr,
  wETHTokenAddr,
  ccipAddr,
  crossAddr,
  wcrossAddr,
  
}