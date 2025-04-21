# Blockchain-Based News Verification System

This system provides blockchain-based verification for news articles in the DailyHunt clone application. It uses Ethereum smart contracts to store and verify the authenticity of news articles.

## Features

- News article publishing to blockchain
- Verification of published articles by trusted verifiers
- Management of trusted publishers and verifiers
- Integration with Flutter application

## Technology Stack

- Solidity: Smart contract development
- Hardhat: Ethereum development environment
- Web3.dart: Flutter integration with Ethereum blockchain

## Smart Contracts

### NewsVerifier.sol

The main smart contract that handles:
- Publishing news articles with content hash and metadata
- Verifying articles by trusted verifiers
- Managing trusted publishers and verifiers

## Setup and Deployment

### Prerequisites

- Node.js (v14+)
- npm or yarn
- MetaMask or other Ethereum wallet

### Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create an `.env` file in the blockchain-verification directory:
   ```
   PRIVATE_KEY=your_wallet_private_key
   SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_infura_project_id
   MUMBAI_RPC_URL=https://polygon-mumbai.infura.io/v3/your_infura_project_id
   ETHERSCAN_API_KEY=your_etherscan_api_key
   ```

### Testing

Run the tests to ensure the smart contracts are working properly:

```bash
npx hardhat test
```

### Deployment

Deploy to Sepolia testnet:

```bash
npx hardhat ignition deploy ignition/modules/deploy-verifier.js --network sepolia
```

Or deploy to local network:

```bash
npx hardhat node
npx hardhat ignition deploy ignition/modules/deploy-verifier.js --network localhost
```

After deployment, update the contract address in the Flutter application's `.env` file.

## Integration with Flutter

1. Update the `.env` file in the Flutter application root with the deployed contract address:
   ```
   RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
   CHAIN_ID=11155111
   NEWS_VERIFIER_ADDRESS=0xYourContractAddressAfterDeployment
   ```

2. Install Flutter application dependencies:
   ```bash
   flutter pub get
   ```

3. Use the `BlockchainService` class to interact with the smart contract.

## Usage

### Publishing News Articles

In the Flutter application:

```dart
final blockchainService = BlockchainService();
final txHash = await blockchainService.publishArticle(
  privateKey: 'YOUR_PRIVATE_KEY',
  content: articleContent,
  metadataUri: 'ipfs://metadata_uri'
);
```

### Verifying News Articles

In the Flutter application:

```dart
final blockchainService = BlockchainService();
final success = await blockchainService.verifyArticle(
  privateKey: 'YOUR_PRIVATE_KEY',
  articleId: 'ARTICLE_ID'
);
```

### Checking Article Verification

In the Flutter application:

```dart
final blockchainService = BlockchainService();
final verification = await blockchainService.checkArticleVerification('ARTICLE_ID');
final isVerified = verification['isVerified'];
final verifierCount = verification['verifierCount'];
```

## Security Considerations

- Private keys should never be hardcoded in the application
- For real applications, integrate a secure wallet solution like WalletConnect
- Always use TLS/SSL for API communication
- Consider implementing a backend service for sensitive blockchain operations

## License

MIT
