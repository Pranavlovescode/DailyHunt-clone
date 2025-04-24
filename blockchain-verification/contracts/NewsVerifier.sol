// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title NewsVerifier
 * @dev Stores and verifies the authenticity of news articles using blockchain
 */
contract NewsVerifier {
    // Structure to store news article information
    struct NewsArticle {
        uint256 timestamp;     // When the article was published
        address publisher;     // Address of the publisher
        bool isVerified;       // Verification status
        address[] verifiers;   // List of addresses that verified this article
        string metadataURI;    // URI to article metadata (could be IPFS link)
    }

    // Mapping from content hash to NewsArticle struct
    mapping(string => NewsArticle) public articles;

    // Mapping to track trusted publishers
    mapping(address => bool) public trustedPublishers;

    // Mapping to track trusted verifiers
    mapping(address => bool) public trustedVerifiers;

    // Owner of the contract
    address public owner;

    // Events
    event ArticlePublished(string indexed contentHash, address publisher);
    event ArticleVerified(string indexed contentHash, address verifier);
    event PublisherAdded(address publisher);
    event PublisherRemoved(address publisher);
    event VerifierAdded(address verifier);
    event VerifierRemoved(address verifier);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyTrustedPublisher() {
        require(trustedPublishers[msg.sender], "Only trusted publishers can perform this action");
        _;
    }

    modifier onlyTrustedVerifier() {
        require(trustedVerifiers[msg.sender], "Only trusted verifiers can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
        // Add contract creator as trusted publisher and verifier
        trustedPublishers[msg.sender] = true;
        trustedVerifiers[msg.sender] = true;
    }

    /**
     * @dev Publish a news article to the blockchain
     * @param _contentHash Hash of the article content
     * @param _metadataURI URI to article metadata
     */
    function publishArticle(string calldata _contentHash, string calldata _metadataURI) 
        external 
        onlyTrustedPublisher 
    {
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(articles[_contentHash].timestamp == 0, "Article with this content hash already exists");

        // Create the new article
        articles[_contentHash] = NewsArticle({
            timestamp: block.timestamp,
            publisher: msg.sender,
            isVerified: false,
            verifiers: new address[](0),
            metadataURI: _metadataURI
        });

        emit ArticlePublished(_contentHash, msg.sender);
    }

    /**
     * @dev Verify a news article using its content hash
     * @param _contentHash Hash of the article content to verify
     */
    function verifyArticle(string calldata _contentHash) external onlyTrustedVerifier {
        NewsArticle storage article = articles[_contentHash];

        // Ensure article exists
        require(article.timestamp > 0, "Article does not exist");

        // Ensure verifier hasn't already verified this article
        for (uint i = 0; i < article.verifiers.length; i++) {
            require(article.verifiers[i] != msg.sender, "You have already verified this article");
        }

        // Add verifier to article's verifiers list
        article.verifiers.push(msg.sender);

        // If this is the first verification, mark article as verified
        if (!article.isVerified) {
            article.isVerified = true;
        }

        emit ArticleVerified(_contentHash, msg.sender);
    }

    /**
     * @dev Check if an article exists and is verified by content hash
     * @param _contentHash Hash of the article content to check
     * @return exists Whether article exists
     * @return isVerified Whether article is verified
     * @return verifierCount Number of verifications
     */
    function checkArticleVerification(string calldata _contentHash) 
        external 
        view 
        returns (bool exists, bool isVerified, uint256 verifierCount) 
    {
        NewsArticle storage article = articles[_contentHash];
        exists = article.timestamp > 0;
        isVerified = article.isVerified;
        verifierCount = article.verifiers.length;
    }

    /**
     * @dev Add a trusted publisher
     * @param _publisher Address of the publisher to add
     */
    function addTrustedPublisher(address _publisher) external onlyOwner {
        trustedPublishers[_publisher] = true;
        emit PublisherAdded(_publisher);
    }

    /**
     * @dev Remove a trusted publisher
     * @param _publisher Address of the publisher to remove
     */
    function removeTrustedPublisher(address _publisher) external onlyOwner {
        trustedPublishers[_publisher] = false;
        emit PublisherRemoved(_publisher);
    }

    /**
     * @dev Add a trusted verifier
     * @param _verifier Address of the verifier to add
     */
    function addTrustedVerifier(address _verifier) external onlyOwner {
        trustedVerifiers[_verifier] = true;
        emit VerifierAdded(_verifier);
    }

    /**
     * @dev Remove a trusted verifier
     * @param _verifier Address of the verifier to remove
     */
    function removeTrustedVerifier(address _verifier) external onlyOwner {
        trustedVerifiers[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }
}