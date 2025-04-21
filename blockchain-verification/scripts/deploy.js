// scripts/deploy.js
const hre = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  console.log("Deploying NewsVerifier contract...");
  
  // Get the contract factory
  const NewsVerifier = await hre.ethers.getContractFactory("NewsVerifier");
  
  // Deploy the contract
  const newsVerifier = await NewsVerifier.deploy();
  
  // Wait for deployment to finish
  await newsVerifier.deployed();
  
  console.log(`NewsVerifier deployed to: ${newsVerifier.address}`);
  
  // Write the contract address to a file for easy access
  const deploymentInfo = {
    address: newsVerifier.address,
    network: hre.network.name,
    chainId: hre.network.config.chainId,
    timestamp: new Date().toISOString()
  };
  
  // Create a .env file with the contract address
  try {
    const envPath = path.join(__dirname, '../../.env');
    let envContent = '';
    
    // Try to read existing .env file
    try {
      if (fs.existsSync(envPath)) {
        envContent = fs.readFileSync(envPath, 'utf8');
      }
    } catch (err) {
      console.log("No existing .env file found, creating new one");
    }
    
    // Add or replace the NEWS_VERIFIER_ADDRESS line
    if (envContent.includes('NEWS_VERIFIER_ADDRESS=')) {
      envContent = envContent.replace(
        /NEWS_VERIFIER_ADDRESS=.*/,
        `NEWS_VERIFIER_ADDRESS=${newsVerifier.address}`
      );
    } else {
      envContent += `\nNEWS_VERIFIER_ADDRESS=${newsVerifier.address}`;
    }
    
    // Add or replace the RPC_URL line for local development
    if (envContent.includes('RPC_URL=')) {
      envContent = envContent.replace(
        /RPC_URL=.*/,
        `RPC_URL=http://127.0.0.1:8545`
      );
    } else {
      envContent += `\nRPC_URL=http://127.0.0.1:8545`;
    }
    
    // Add or replace the CHAIN_ID line
    if (envContent.includes('CHAIN_ID=')) {
      envContent = envContent.replace(
        /CHAIN_ID=.*/,
        `CHAIN_ID=${hre.network.config.chainId}`
      );
    } else {
      envContent += `\nCHAIN_ID=${hre.network.config.chainId}`;
    }
    
    // Write the updated content back
    fs.writeFileSync(envPath, envContent.trim());
    console.log(`Updated .env file with contract address and network details`);
  } catch (err) {
    console.error("Error writing .env file:", err);
  }
  
  // Also write to a deployment json file
  const deploymentsDir = path.join(__dirname, '../deployments');
  
  // Create deployments directory if it doesn't exist
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }
  
  const filePath = path.join(deploymentsDir, `${hre.network.name}.json`);
  fs.writeFileSync(filePath, JSON.stringify(deploymentInfo, null, 2));
  console.log(`Deployment info saved to ${filePath}`);
}

// Execute deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });