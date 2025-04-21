// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title NewsVerifier
 * @dev Stores and verifies the authenticity of news articles using blockchain
 */
contract NewsVerifier {
    // Structure to store news article information
    struct NewsArticle {
        string contentHash;    // IPFS hash or SHA-256 hash of the article content
        uint256 timestamp;     // When the article was published
        address publisher;     // Address of the publisher
        bool isVerified;       // Verification status
        address[] verifiers;   // List of addresses that verified this article
        string metadataURI;    // URI to article metadata (could be IPFS link)
    }
    
    // Mapping from article ID to NewsArticle struct
    mapping(bytes32 => NewsArticle) public articles;
    
    // Mapping to track trusted publishers
    mapping(address => bool) public trustedPublishers;
    
    // Mapping to track trusted verifiers
    mapping(address => bool) public trustedVerifiers;
    
    // Owner of the contract
    address public owner;
    
    // Events
    event ArticlePublished(bytes32 indexed articleId, string contentHash, address publisher);
    event ArticleVerified(bytes32 indexed articleId, address verifier);
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
    
    /**
     * @dev Publish a news article to the blockchain
     * @param _contentHash Hash of the article content
     * @param _metadataURI URI to article metadata
     * @return articleId Unique ID of the published article
     */
    function publishArticle(string calldata _contentHash, string calldata _metadataURI) 
        external 
        onlyTrustedPublisher 
        returns (bytes32 articleId) 
    {
        // Create a unique ID for the article based on content hash and publisher
        articleId = keccak256(abi.encodePacked(_contentHash, msg.sender, block.timestamp));
        
        // Ensure article doesn't already exist
        require(articles[articleId].timestamp == 0, "Article already exists");
        
        // Create the new article
        articles[articleId] = NewsArticle({
            contentHash: _contentHash,
            timestamp: block.timestamp,
            publisher: msg.sender,
            isVerified: false,
            verifiers: new address[](0),
            metadataURI: _metadataURI
        });
        
        emit ArticlePublished(articleId, _contentHash, msg.sender);
        return articleId;
    }
    
    /**
     * @dev Verify a news article
     * @param _articleId ID of the article to verify
     */
    function verifyArticle(bytes32 _articleId) external onlyTrustedVerifier {
        NewsArticle storage article = articles[_articleId];
        
        // Ensure article exists
        require(article.timestamp > 0, "Article does not exist");
        
        // Ensure verifier hasn't already verified this article
        bool alreadyVerified = false;
        for (uint i = 0; i < article.verifiers.length; i++) {
            if (article.verifiers[i] == msg.sender) {
                alreadyVerified = true;
                break;
            }
        }
        require(!alreadyVerified, "You have already verified this article");
        
        // Add verifier to article's verifiers list
        article.verifiers.push(msg.sender);
        
        // If this is the first verification, mark article as verified
        if (!article.isVerified) {
            article.isVerified = true;
        }
        
        emit ArticleVerified(_articleId, msg.sender);
    }
    
    /**
     * @dev Get article details
     * @param _articleId ID of the article
     * @return contentHash Hash of article content
     * @return timestamp When article was published
     * @return publisher Address of publisher
     * @return isVerified Verification status
     * @return verifierCount Number of verifiers
     * @return metadataURI URI to article metadata
     */
    function getArticle(bytes32 _articleId) 
        external 
        view 
        returns (
            string memory contentHash,
            uint256 timestamp,
            address publisher,
            bool isVerified,
            uint256 verifierCount,
            string memory metadataURI
        ) 
    {
        NewsArticle storage article = articles[_articleId];
        require(article.timestamp > 0, "Article does not exist");
        
        return (
            article.contentHash,
            article.timestamp,
            article.publisher,
            article.isVerified,
            article.verifiers.length,
            article.metadataURI
        );
    }
    
    /**
     * @dev Check if an article exists and is verified
     * @param _articleId ID of the article to check
     * @return exists Whether article exists
     * @return isVerified Whether article is verified
     * @return verifierCount Number of verifications
     */
    function checkArticleVerification(bytes32 _articleId) 
        external 
        view 
        returns (bool exists, bool isVerified, uint256 verifierCount) 
    {
        NewsArticle storage article = articles[_articleId];
        exists = article.timestamp > 0;
        isVerified = article.isVerified;
        verifierCount = article.verifiers.length;
    }
}