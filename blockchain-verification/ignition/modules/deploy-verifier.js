const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("NewsVerifierModule", (m) => {
  // Deploy the NewsVerifier contract
  const newsVerifier = m.contract("NewsVerifier");
  
  return { newsVerifier };
});