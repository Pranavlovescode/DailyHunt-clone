import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:crypto/crypto.dart';
import 'dart:async';

class BlockchainService {
  // Multiple RPC options to fallback to if the local node is not available
  static const List<Map<String, dynamic>> _rpcOptions = [
    {
      'url': 'https://sepolia.infura.io/v3/9ae4419a4d1a4e37820d0b19d9bf74a7', // Replace with your actual Infura key
      'chainId': 11155111, // Sepolia testnet
      'name': 'Sepolia Testnet',
      'contractAddress': '0x7001674FFb5A0d7173a29Cdee4eDEDb676595be1' // Add your deployed contract address on Sepolia
    },
    {
      'url': 'http://127.0.0.1:8545/', // Local Hardhat network URL
      'chainId': 31337, // Local Hardhat network chain ID
      'name': 'Local Hardhat',
      'contractAddress': '0x5FbDB2315678afecb367f032d93F642f64180aa3' // Local contract address
    },
    {
      'url': 'https://linea-sepolia.blastapi.io/cbb7887b-e443-46ad-9651-d82bcfdf8370', // Public RPC for Linea Sepolia
      'chainId': 5, // Chain ID labeled as Goerli in your logs
      'name': 'Linea Sepolia Testnet',
      'contractAddress': '' // You need to deploy and add your contract address here
    }
  ];
  
  // Use nullable types for late initialization to avoid crashes
  Web3Client? _web3client;
  EthereumAddress? _contractAddress;
  DeployedContract? _contract;
  ContractFunction? _publishArticle;
  ContractFunction? _verifyArticle;
  ContractFunction? _checkArticleVerification;
  ContractFunction? _getArticle;
  int? _chainId;
  String _rpcUrl = '';
  String _networkName = '';
  
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isNodeConnected = false;
  
  // Store the contract ABI as string once loaded
  String? _contractAbiString;
  
  // Completer to track initialization status
  final Completer<bool> _initCompleter = Completer<bool>();

  // Singleton pattern
  static final BlockchainService _instance = BlockchainService._internal();
  
  factory BlockchainService() {
    return _instance;
  }

  BlockchainService._internal() {
    // Don't automatically initialize - we'll do this when needed
  }

  // Initialize on demand, when actually needed
  Future<bool> ensureInitialized() async {
    if (_isInitialized) {
      return _isNodeConnected;
    }
    
    // If already initializing, wait for it to complete
    if (_isInitializing) {
      return _initCompleter.future;
    }
    
    _isInitializing = true;
    
    try {
      await _initializeBase();
      _isInitialized = true;
      print("✅ BlockchainService initialized successfully");
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(_isNodeConnected);
      }
      return _isNodeConnected;
    } catch (error) {
      print("⚠️ BlockchainService initialization failed: $error");
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete(false);
      }
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  // Initialize only the base components (web3 client, etc.)
  Future<void> _initializeBase() async {
    try {
      // Try connecting to each RPC provider in order until one works
      bool connected = false;
      Exception? lastError;
      String? networkContractAddress;
      
      // First check if we have RPC_URL in .env
      String? envRpcUrl;
      int? envChainId;
      
      try {
        envRpcUrl = dotenv.env['RPC_URL'];
        final chainIdStr = dotenv.env['CHAIN_ID'];
        if (chainIdStr != null && chainIdStr.isNotEmpty) {
          envChainId = int.tryParse(chainIdStr);
        }
      } catch (e) {
        print("Warning: Could not load environment variables: $e");
      }
      
      // Try using the .env RPC URL if provided
      if (envRpcUrl != null && envRpcUrl.isNotEmpty) {
        connected = await _tryConnectRpc(
          envRpcUrl, 
          envChainId ?? _rpcOptions[0]['chainId'] as int,
          'Custom RPC from .env'
        );
      }
      
      // If not connected with .env URL, try the fallback options
      if (!connected) {
        // Try each RPC option in order until one connects
        for (final rpcOption in _rpcOptions) {
          try {
            connected = await _tryConnectRpc(
              rpcOption['url'] as String,
              rpcOption['chainId'] as int,
              rpcOption['name'] as String
            );
            
            if (connected) {
              networkContractAddress = rpcOption['contractAddress'] as String?;
              break;
            }
          } catch (e) {
            lastError = e as Exception;
            print("Failed to connect to ${rpcOption['name']}: $e");
          }
        }
      }
      
      if (!connected) {
        print("❌ Failed to connect to any blockchain node");
        // We'll continue with the service in offline mode
        if (lastError != null) {
          throw lastError;
        }
      }
      
      // Get appropriate contract address based on the network we're connected to
      String contractAddressHex;
      try {
        // First try from environment variables
        contractAddressHex = dotenv.env['NEWS_VERIFIER_ADDRESS'] ?? '0x7BC66849c2810a86240B3c725Cc6C9bfbd6F1895';
        
        // If not in env vars, check if we have a network-specific address
        if (contractAddressHex.isEmpty && networkContractAddress != null && networkContractAddress.isNotEmpty) {
          contractAddressHex = networkContractAddress;
        }
        
        // If still empty, try to get contract address for current chain ID
        if (contractAddressHex.isEmpty && _chainId != null) {
          final matchingNetwork = _rpcOptions.firstWhere(
            (option) => option['chainId'] == _chainId && 
                        option['contractAddress'] != null && 
                        option['contractAddress'].isNotEmpty,
            orElse: () => {
              'contractAddress': '', 
              'name': 'Unknown'
            }
          );
          
          if (matchingNetwork['contractAddress'] != null && 
              matchingNetwork['contractAddress'].isNotEmpty) {
            contractAddressHex = matchingNetwork['contractAddress'] as String;
            print("📝 Using contract address for ${matchingNetwork['name']}: $contractAddressHex");
          }
        }
        
        // If still not found, use local default as last resort
        if (contractAddressHex.isEmpty) {
          print("⚠️ Warning: No contract address found for current network, using local default address");
          contractAddressHex = _rpcOptions[0]['contractAddress'] as String;
        }
      } catch (e) {
        print("⚠️ Error determining contract address: $e");
        contractAddressHex = _rpcOptions[0]['contractAddress'] as String;
      }
      
      // Set contract address
      _contractAddress = EthereumAddress.fromHex(contractAddressHex);
      print("📝 Using contract at address: ${_contractAddress!.hex}");
      
    } catch (e) {
      print("Error during blockchain service base initialization: $e");
      // We don't throw here to allow the app to continue in offline mode
    }
  }
  
  // Try to connect to a specific RPC provider
  Future<bool> _tryConnectRpc(String url, int chainId, String networkName) async {
    try {
      print("🔌 Attempting to connect to $networkName at $url");
      
      // Create a client with a 5 second timeout
      final client = http.Client();
      final web3client = Web3Client(url, client);
      
      // Try to get the network ID to verify connection
      await web3client.getNetworkId().timeout(const Duration(seconds: 5));
      
      // If we get here, connection was successful
      _web3client?.dispose(); // Dispose any existing client
      _web3client = web3client;
      _chainId = chainId;
      _rpcUrl = url;
      _networkName = networkName;
      _isNodeConnected = true;
      
      print("✅ Connected to $networkName (Chain ID: $chainId)");
      return true;
    } catch (e) {
      print("❌ Failed to connect to $networkName: $e");
      return false;
    }
  }
  
  // Load the contract ABI and initialize contract-related components
  Future<bool> _loadContractData() async {
    if (_contract != null) {
      return true; // Already loaded
    }
    
    try {
      // Try to load contract ABI from the JSON file if not already loaded
      if (_contractAbiString == null) {
        _contractAbiString = await rootBundle.loadString('assets/abi/NewsVerifier.json');
      }
      
      final abiJson = json.decode(_contractAbiString!);
      
      // Create contract instance
      _contract = DeployedContract(
        ContractAbi.fromJson(json.encode(abiJson['abi']), 'NewsVerifier'), 
        _contractAddress!
      );
      
      // Initialize contract functions
      _publishArticle = _contract!.function('publishArticle');
      _verifyArticle = _contract!.function('verifyArticle');
      _checkArticleVerification = _contract!.function('checkArticleVerification');
      _getArticle = _contract!.function('getArticle');
      
      return true;
    } catch (e) {
      print("Failed to load contract ABI: $e");
      return false;
    }
  }

  /// Returns the name of the connected network or "Not Connected" if not connected
  String get networkName => _isNodeConnected ? _networkName : "Not Connected";
  
  /// Returns true if connected to a blockchain node
  bool get isConnected => _isNodeConnected;

  /// Checks if the service is properly initialized
  bool get isInitialized => _isInitialized && _web3client != null;

  /// Checks if the contract is loaded
  bool get isContractLoaded => _contract != null;

  /// Get connection status and information
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isInitialized': _isInitialized,
      'isConnected': _isNodeConnected,
      'networkName': _networkName,
      'rpcUrl': _rpcUrl,
      'chainId': _chainId,
      'contractAddress': _contractAddress?.hex ?? 'Not set',
    };
  }

  /// Generates a content hash from an article body
  String generateContentHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString()}';
  }

  /// Publish an article to the blockchain
  Future<Map<String, dynamic>?> publishArticle({
    required String privateKey,
    required String content,
    String? metadataUri = 'news://dailyhunt/article',
  }) async {
    if (!isInitialized && !(await ensureInitialized())) {
      print('BlockchainService: not initialized');
      return {'error': 'Service not initialized'};
    }

    if (!_isNodeConnected) {
      print('BlockchainService: not connected to blockchain');
      return {'error': 'Not connected to blockchain'};
    }

    try {
      // Generate content hash from article content
      final contentHash = generateContentHash(content);
      print('Generated content hash: $contentHash');

      // Create credentials from private key
      final credentials = EthPrivateKey.fromHex(privateKey);
      
      // Use empty string if metadataUri is null
      final uri = metadataUri ?? 'news://dailyhunt/article';

      print('Publishing article with content hash: $contentHash');
      print('Using contract at: ${_contractAddress?.hex}');
      print('Publisher address: ${credentials.address.hex}');
      print('Metadata URI: $uri');

      // Call publishArticle function
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _publishArticle!,
        parameters: [contentHash, uri],
      );

      // Send transaction
      final txHash = await _web3client!.sendTransaction(
        credentials,
        transaction,
        chainId: _chainId,
      );

      print('Transaction hash: $txHash');
      
      // Wait for the transaction to be processed
      TransactionReceipt? receipt;
      int attempts = 0;
      const maxAttempts = 10;
      
      while (receipt == null && attempts < maxAttempts) {
        try {
          receipt = await _web3client!.getTransactionReceipt(txHash);
        } catch (e) {
          print('Error getting receipt: $e');
        }
        
        if (receipt == null) {
          await Future.delayed(const Duration(seconds: 2));
          attempts++;
          print('Waiting for receipt... (attempt $attempts/$maxAttempts)');
        }
      }

      if (receipt == null) {
        return {
          'contentHash': contentHash,
          'txHash': txHash,
          'status': 'pending',
          'message': 'Transaction submitted but not confirmed yet'
        };
      }

      return {
        'contentHash': contentHash,
        'txHash': txHash,
        'status': receipt.status! ? 'success' : 'failed',
        'blockNumber': (receipt.blockNumber?.blockNum ?? 0).toString(),
      };
    } catch (e) {
      print('Error publishing article: $e');
      return {'error': e.toString()};
    }
  }

  /// Verifies an article on the blockchain using content hash directly
  Future<bool> verifyArticle({
    required String privateKey,
    required String contentHash,
    String? content,
  }) async {
    if (!isInitialized && !(await ensureInitialized())) {
      print('BlockchainService: not initialized');
      return false;
    }

    if (!_isNodeConnected) {
      print('BlockchainService: not connected to blockchain');
      return false;
    }

    try {
      // Load contract data if needed
      if (!isContractLoaded && !(await _loadContractData())) {
        print('Failed to load contract data');
        return false;
      }

      // Format content hash if needed
      if (contentHash.isEmpty && content != null) {
        contentHash = generateContentHash(content);
        print('Generated content hash: $contentHash');
      }

      String formattedHash = contentHash;
      if (!formattedHash.startsWith('0x')) {
        formattedHash = '0x$contentHash';
      }

      // Create credentials from private key
      final credentials = EthPrivateKey.fromHex(privateKey);
      
      print('Verifying article with content hash: $formattedHash');
      print('Using contract at: ${_contractAddress?.hex}');
      print('Verifier address: ${credentials.address.hex}');

      // Call verifyArticle function with the content hash
      final transaction = Transaction.callContract(
        contract: _contract!,
        function: _verifyArticle!,
        parameters: [formattedHash],
      );

      // Send transaction
      final txHash = await _web3client!.sendTransaction(
        credentials,
        transaction,
        chainId: _chainId,
      );

      print('Transaction hash: $txHash');
      
      // Wait for the transaction to be processed
      bool confirmed = false;
      int attempts = 0;
      const maxAttempts = 10;
      
      while (!confirmed && attempts < maxAttempts) {
        try {
          final receipt = await _web3client!.getTransactionReceipt(txHash);
          if (receipt != null) {
            confirmed = receipt.status!;
            print('Transaction confirmed: ${receipt.status}');
            if (!confirmed) {
              print('Transaction failed: ${receipt.logs}');
            }
            break;
          }
        } catch (e) {
          print('Error getting receipt: $e');
        }
        
        await Future.delayed(const Duration(seconds: 2));
        attempts++;
        print('Waiting for confirmation... (attempt $attempts/$maxAttempts)');
      }

      return confirmed;
    } catch (e) {
      print('Error verifying article: $e');
      return false;
    }
  }

  /// Checks if an article exists and is verified on the blockchain
  Future<Map<String, dynamic>> checkArticleVerification(String contentHash) async {
    // Ensure initialization
    if (!isInitialized && !(await ensureInitialized())) {
      print('BlockchainService initialization failed');
      return {
        'exists': false,
        'isVerified': false,
        'verifierCount': 0,
        'error': 'BlockchainService not initialized',
      };
    }
    
    if (!_isNodeConnected) {
      print('Not connected to any blockchain node');
      return {
        'exists': false,
        'isVerified': false,
        'verifierCount': 0,
        'error': 'No blockchain connection',
        'connectionDetails': getConnectionInfo(),
      };
    }
    
    // Load contract data if needed
    if (!isContractLoaded && !(await _loadContractData())) {
      print('Failed to load contract data');
      return {
        'exists': false,
        'isVerified': false,
        'verifierCount': 0,
        'error': 'Contract data not loaded',
      };
    }
    
    try {
      // Make sure the hash is in the correct format (0x prefixed)
      String formattedHash = contentHash;
      if (!formattedHash.startsWith('0x')) {
        formattedHash = '0x$formattedHash';
      }
      
      print('📝 Checking verification for content hash: $formattedHash');
      print('📝 Using contract at: ${_contractAddress?.hex}');
      print('📝 Network: $_networkName (Chain ID: $_chainId)');
      
      // Call contract with the content hash directly
      final result = await _web3client!.call(
        contract: _contract!,
        function: _checkArticleVerification!,
        params: [formattedHash],
      );
      
      print('Raw verification result: $result');
      
      final details = {
        'exists': result[0] as bool,
        'isVerified': result[1] as bool,
        'verifierCount': (result[2] as BigInt).toInt(),
        'networkName': _networkName,
        'contentHash': formattedHash,
      };
      
      print('📝 Verification details: $details');
      return details;
    } catch (e) {
      print('Error checking article verification: $e');
      return {
        'exists': false,
        'isVerified': false,
        'verifierCount': 0,
        'error': e.toString(),
        'networkName': _networkName,
      };
    }
  }

  /// Gets article details from the blockchain by content hash
  Future<Map<String, dynamic>?> getArticle(String contentHash) async {
    // Ensure initialization
    if (!isInitialized && !(await ensureInitialized())) {
      print('BlockchainService initialization failed');
      return null;
    }
    
    if (!_isNodeConnected) {
      print('Not connected to any blockchain node');
      return {
        'error': 'No blockchain connection',
        'connectionDetails': getConnectionInfo(),
      };
    }
    
    // Load contract data if needed
    if (!isContractLoaded && !(await _loadContractData())) {
      print('Failed to load contract data');
      return null;
    }
    
    try {
      // Format content hash if needed
      String formattedHash = contentHash;
      if (!formattedHash.startsWith('0x')) {
        formattedHash = '0x$contentHash';
      }
      
      // Call getArticle function
      final result = await _web3client!.call(
        contract: _contract!,
        function: _getArticle!,
        params: [formattedHash],
      );
      
      if (result.isNotEmpty && result.length >= 5) {
        return {
          'contentHash': formattedHash,
          'timestamp': (result[0] as BigInt).toInt(),
          'publisher': (result[1] as EthereumAddress).hex,
          'isVerified': result[2] as bool,
          'verifierCount': (result[3] as BigInt).toInt(),
          'metadataURI': result[4] as String,
          'networkName': _networkName,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting article details: $e');
      return {
        'error': e.toString(),
        'networkName': _networkName,
      };
    }
  }

  /// Attempts to reconnect to the blockchain node
  Future<bool> reconnect() async {
    print("🔄 Attempting to reconnect to blockchain network...");
    
    _isNodeConnected = false;
    
    // Dispose old client if any
    if (_web3client != null) {
      _web3client!.dispose();
      _web3client = null;
    }
    
    // Reset initialization flag
    _isInitialized = false;
    
    // Try to initialize again
    return await ensureInitialized();
  }

  /// Disconnects the Web3 client
  void dispose() {
    if (_web3client != null) {
      _web3client!.dispose();
    }
  }
}