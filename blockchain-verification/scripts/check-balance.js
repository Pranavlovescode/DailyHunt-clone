const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Checking balance for account:", deployer.address);
  
  const balanceWei = await ethers.provider.getBalance(deployer.address);
  const balanceEth = ethers.formatEther(balanceWei);
  
  console.log(`Balance: ${balanceEth} ETH`);
  console.log(`Raw balance: ${balanceWei.toString()} Wei`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });