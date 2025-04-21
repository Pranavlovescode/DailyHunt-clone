const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NewsVerifier", function () {
  let newsVerifier;
  let owner, publisher1, publisher2, verifier1, verifier2;

  before(async function () {
    // Get signers
    [owner, publisher1, publisher2, verifier1, verifier2] = await ethers.getSigners();
    
    // Deploy the contract
    const NewsVerifier = await ethers.getContractFactory("NewsVerifier");
    newsVerifier = await NewsVerifier.deploy();
    await newsVerifier.waitForDeployment();
  });

  describe("Initialization", function () {
    it("Should set the right owner", async function () {
      expect(await newsVerifier.owner()).to.equal(owner.address);
    });

    it("Should set contract creator as trusted publisher and verifier", async function () {
      expect(await newsVerifier.trustedPublishers(owner.address)).to.equal(true);
      expect(await newsVerifier.trustedVerifiers(owner.address)).to.equal(true);
    });
  });

  describe("Publisher and Verifier Management", function () {
    it("Should add trusted publisher", async function () {
      await newsVerifier.addTrustedPublisher(publisher1.address);
      expect(await newsVerifier.trustedPublishers(publisher1.address)).to.equal(true);
    });

    it("Should add trusted verifier", async function () {
      await newsVerifier.addTrustedVerifier(verifier1.address);
      expect(await newsVerifier.trustedVerifiers(verifier1.address)).to.equal(true);
    });

    it("Should remove trusted publisher", async function () {
      await newsVerifier.removeTrustedPublisher(publisher1.address);
      expect(await newsVerifier.trustedPublishers(publisher1.address)).to.equal(false);
    });

    it("Should remove trusted verifier", async function () {
      await newsVerifier.removeTrustedVerifier(verifier1.address);
      expect(await newsVerifier.trustedVerifiers(verifier1.address)).to.equal(false);
    });

    it("Should fail when non-owner adds publisher", async function () {
      await expect(
        newsVerifier.connect(publisher2).addTrustedPublisher(publisher2.address)
      ).to.be.revertedWith("Only owner can perform this action");
    });
  });

  describe("Article Publishing and Verification", function () {
    let articleId;
    const contentHash = "QmT5NvUtoM5nWFM4kGQZe1J1Y1rMqMDHf6sGV3dV9cu8PX"; // Example IPFS hash
    const metadataURI = "ipfs://QmT5NvUtoM5nWFM4kGQZe1J1Y1rMqMDHf6sGV3dV9cu8PX/metadata.json";

    before(async function () {
      // Re-add publisher1 and verifier1 for testing
      await newsVerifier.addTrustedPublisher(publisher1.address);
      await newsVerifier.addTrustedVerifier(verifier1.address);
    });

    it("Should allow trusted publisher to publish article", async function () {
      const tx = await newsVerifier.connect(publisher1).publishArticle(contentHash, metadataURI);
      const receipt = await tx.wait();
      
      // Find the event in the receipt
      const event = receipt.logs.find(
        log => log.fragment && log.fragment.name === 'ArticlePublished'
      );
      
      // Get articleId from event
      articleId = event.args.articleId;
      
      // Verify article information
      const article = await newsVerifier.getArticle(articleId);
      expect(article[0]).to.equal(contentHash);
      expect(article[2]).to.equal(publisher1.address);
      expect(article[3]).to.equal(false); // isVerified should be false initially
      expect(article[5]).to.equal(metadataURI);
    });

    it("Should allow trusted verifier to verify article", async function () {
      await newsVerifier.connect(verifier1).verifyArticle(articleId);
      
      const article = await newsVerifier.getArticle(articleId);
      expect(article[3]).to.equal(true); // isVerified should be true now
      expect(article[4]).to.equal(1);    // verifierCount should be 1
    });

    it("Should not allow the same verifier to verify the article twice", async function () {
      await expect(
        newsVerifier.connect(verifier1).verifyArticle(articleId)
      ).to.be.revertedWith("You have already verified this article");
    });

    it("Should check article verification status", async function () {
      const verification = await newsVerifier.checkArticleVerification(articleId);
      expect(verification[0]).to.equal(true);  // exists
      expect(verification[1]).to.equal(true);  // isVerified
      expect(verification[2]).to.equal(1);     // verifierCount
    });

    it("Should fail when non-trusted publisher publishes article", async function () {
      await expect(
        newsVerifier.connect(publisher2).publishArticle(contentHash, metadataURI)
      ).to.be.revertedWith("Only trusted publishers can perform this action");
    });

    it("Should fail when non-trusted verifier verifies article", async function () {
      await expect(
        newsVerifier.connect(verifier2).verifyArticle(articleId)
      ).to.be.revertedWith("Only trusted verifiers can perform this action");
    });
  });
});