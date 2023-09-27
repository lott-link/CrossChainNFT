async function deployFee(contractName, ...arguments) {

  const Contract = await hre.ethers.getContractFactory(contractName);
  const deploymentData = Contract.getDeployTransaction(...arguments).data;

  const gasEstimate = await hre.ethers.provider.estimateGas({
    data: deploymentData,
  });

  const gasPrice = (await ethers.provider.getFeeData()).gasPrice;
  const gasFee = Number(gasEstimate) * Number(gasPrice);
  const gasFeeInEth = ethers.formatEther(gasFee);

  console.log("Deployment ...")
  console.log("Estimated gas:", gasEstimate.toString());
  console.log("Gas price:", gasPrice.toString());
  console.log("Gas fee (ETH):", gasFeeInEth.toString());
}

async function callFee(contract, functionName, ...arguments) {

  const functionFragment = contract.interface.getFunction(functionName);
  const callData = contract.interface.encodeFunctionData(functionFragment, arguments);

  const gasEstimate = await ethers.provider.estimateGas({
    to : contract.target,
    data: callData,
  });

  const gasPrice = (await ethers.provider.getFeeData()).gasPrice;
  const gasFee = Number(gasEstimate) * Number(gasPrice);
  const gasFeeInEth = ethers.formatEther(gasFee);

  console.log("function call: ", functionName, "(", ...arguments, ")");
  console.log("Estimated gas:", gasEstimate.toString());
  console.log("Gas price:", gasPrice.toString());
  console.log("Gas fee (ETH):", gasFeeInEth.toString());
}

module.exports = {
  deployFee,
  callFee
};
