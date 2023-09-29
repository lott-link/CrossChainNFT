const { network } = require("hardhat");

const zero_address = "0x0000000000000000000000000000000000000000"

let nftAddr = zero_address
let routerAddr = zero_address
let desChainSelector = 0
let chainSelector = 0
let linkTokenAddr = zero_address
let wETHTokenAddr = zero_address
let ccipAddr = zero_address
let crossAddr = "0x8381BA26034E7559925F78881Bd82744f4a15d26"
let wcrossAddr = "0x8381BA26034E7559925F78881Bd82744f4a15d26"

if(network.config.chainId == 1) {

  routerAddr = "0xE561d5E02207fb5eB32cca20a699E0d8919a1476"
  chainSelector = "5009297550715157269" // ethereum chain selector
  desChainSelector = "4051577828743386545" // polygon chain selector
  linkTokenAddr = "0x514910771AF9Ca656af840dff83E8264EcF986CA"
  wETHTokenAddr = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"

} else if(network.config.chainId == 137) {

  routerAddr = "0x3C3D92629A02a8D95D5CB9650fe49C3544f69B43"
  chainSelector = "4051577828743386545" // polygon chain selector
  desChainSelector = "5009297550715157269" // ethereum chain selector
  linkTokenAddr = "0xb0897686c545045aFc77CF20eC7A532E3120E0F1"
  wETHTokenAddr = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270" // wMATIC
  ccipAddr = "0xd6fecB12ae2c23069369Cc62f9470176a648b59a"

} else if(network.config.chainId == 11155111) {

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