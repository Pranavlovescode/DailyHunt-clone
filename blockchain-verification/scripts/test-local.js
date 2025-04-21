// Local testing script for the NewsVerifier contract
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  console.log("Starting local blockchain verification system test...");

  // Get contract factory and deploy it
  const NewsVerifier = await ethers.getContractFactory("NewsVerifier");
  console.log("Deploying NewsVerifier contract...");
  const newsVerifier = await NewsVerifier.deploy();
  await newsVerifier.deployed();

  console.log(`NewsVerifier deployed to: ${newsVerifier.address}`);

  // Get signers for testing
  const [owner, publisher, verifier1, verifier2, reader] = await ethers.getSigners();
  
  console.log(`\nAccounts used for testing:`);
  console.log(`Owner: ${owner.address}`);
  console.log(`Publisher: ${publisher.address}`);
  console.log(`Verifier1: ${verifier1.address}`);
  console.log(`Verifier2: ${verifier2.address}`);
  console.log(`Reader: ${reader.address}`);

  // Add publisher as trusted publisher
  console.log(`\nAdding trusted publisher: ${publisher.address}`);
  await newsVerifier.addTrustedPublisher(publisher.address);
  console.log("Publisher added successfully");

  // Add verifiers as trusted verifiers
  console.log(`\nAdding trusted verifiers: ${verifier1.address}, ${verifier2.address}`);
  await newsVerifier.addTrustedVerifier(verifier1.address);
  await newsVerifier.addTrustedVerifier(verifier2.address);
  console.log("Verifiers added successfully");

  // Publish test article
  console.log("\nPublishing test article...");
  const contentHash = "0x" + Buffer.from("Test article content hash").toString("hex");
  const metadataUri = "ipfs://test-metadata-uri";
  
  const publishTx = await newsVerifier.connect(publisher).publishArticle(contentHash, metadataUri);
  const publishReceipt = await publishTx.wait();
  
  // Extract the article ID from logs
  const publishEvent = publishReceipt.events.find(e => e.event === 'ArticlePublished');
  const articleId = publishEvent.args.articleId;
  console.log(`Article published with ID: ${articleId}`);
  
  // Check article verification status
  console.log("\nChecking article verification status...");
  const initialVerification = await newsVerifier.checkArticleVerification(articleId);
  console.log(`Initial verification status: exists=${initialVerification[0]}, verified=${initialVerification[1]}, verifierCount=${initialVerification[2]}`);
  
  // Verify the article with verifier1
  console.log("\nVerifying article with first verifier...");
  await newsVerifier.connect(verifier1).verifyArticle(articleId);
  
  // Check article verification status again
  const midVerification = await newsVerifier.checkArticleVerification(articleId);
  console.log(`Verification status after first verifier: exists=${midVerification[0]}, verified=${midVerification[1]}, verifierCount=${midVerification[2]}`);
  
  // Verify the article with verifier2
  console.log("\nVerifying article with second verifier...");
  await newsVerifier.connect(verifier2).verifyArticle(articleId);
  
  // Check final article verification status
  const finalVerification = await newsVerifier.checkArticleVerification(articleId);
  console.log(`Final verification status: exists=${finalVerification[0]}, verified=${finalVerification[1]}, verifierCount=${finalVerification[2]}`);
  
  // Get the full article details
  console.log("\nGetting full article details...");
  const article = await newsVerifier.getArticle(articleId);
  console.log(`Article details:
  Content Hash: ${article.contentHash}
  Published at: ${new Date(article.timestamp * 1000).toLocaleString()}
  Publisher: ${article.publisher}
  Verified: ${article.isVerified}
  Verifier Count: ${article.verifierCount}
  Metadata URI: ${article.metadataURI}
  `);

  // Update the .env file with this contract address
  console.log("\n===================================================");
  console.log("✅ Test completed successfully!");
  console.log("===================================================");
  console.log(`\nTo use this contract in your Flutter app, update your .env file with:`);
  console.log(`NEWS_VERIFIER_ADDRESS=${newsVerifier.address}`);
  console.log(`\nSome test accounts for your Flutter app:`);
  console.log(`Publisher: ${publisher.address} (Private Key in Hardhat node output)`);
  console.log(`Verifier: ${verifier1.address} (Private Key in Hardhat node output)`);
}

// Execute the script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });