import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dailyhunt/services/blockchain_service.dart';
import 'package:crypto/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'dart:convert';

class HashVerificationPage extends StatefulWidget {
  const HashVerificationPage({Key? key}) : super(key: key);

  @override
  State<HashVerificationPage> createState() => _HashVerificationPageState();
}

class _HashVerificationPageState extends State<HashVerificationPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _metadataUriController = TextEditingController();

  bool _isLoading = false;
  final BlockchainService _blockchainService = BlockchainService();
  Map<String, dynamic>? _verificationResult;
  String? _error;
  bool _isConnected = false;
  String _networkName = "Not connected";
  bool _showPublishForm = false;

  @override
  void initState() {
    super.initState();
    _initBlockchainService();
    _metadataUriController.text = 'news://dailyhunt/article';
  }

  @override
  void dispose() {
    _contentController.dispose();
    _hashController.dispose();
    _privateKeyController.dispose();
    _metadataUriController.dispose();
    super.dispose();
  }

  Future<void> _initBlockchainService() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final initialized = await _blockchainService.ensureInitialized();

      setState(() {
        _isLoading = false;
        _isConnected = _blockchainService.isConnected;
        _networkName = _blockchainService.networkName;
      });

      if (!initialized) {
        setState(() {
          _error = 'Failed to initialize blockchain service';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: ${e.toString()}';
      });
    }
  }

  void _generateHash() {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter content to hash'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final content = _contentController.text;
    final hash = _blockchainService.generateContentHash(content);

    setState(() {
      _hashController.text = hash;
    });
  }

  Future<void> _publishToBlockchain() async {
    // Validate inputs
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter content to publish'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_privateKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a private key'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _verificationResult = null;
    });

    try {
      if (!_isConnected) {
        await _blockchainService.reconnect();
        setState(() {
          _isConnected = _blockchainService.isConnected;
          _networkName = _blockchainService.networkName;
        });
      }

      if (!_isConnected) {
        throw Exception('Not connected to blockchain');
      }

      // Generate hash if not already done
      if (_hashController.text.isEmpty) {
        _generateHash();
      }

      // Get wallet address from private key
      final privateKey = _privateKeyController.text.trim();
      final credentials = EthPrivateKey.fromHex(privateKey);
      final walletAddress = credentials.address.hex;
      
      // Get content hash for publication
      final contentHash = _hashController.text.trim();

      print('📝 Content hash for publication: $contentHash');
      print('📝 Publisher wallet address: $walletAddress');

      // Show publishing message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publishing to blockchain... This may take a minute.'),
            backgroundColor: Color(0xFF3498DB),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Use the blockchain service to publish the article
      final result = await _blockchainService.publishArticle(
        privateKey: privateKey,
        content: _contentController.text,
        metadataUri: _metadataUriController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      if (result == null) {
        throw Exception('Failed to publish to blockchain');
      }

      if (result.containsKey('error')) {
        throw Exception(result['error']);
      }

      // Extract transaction hash for user feedback
      final txHash = result['txHash'] as String;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully published to blockchain! TX: ${txHash.substring(0, 10)}...'),
            backgroundColor: const Color(0xFF2ECC71),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Use the contentHash directly for verification
      _hashController.text = result['contentHash'] ?? contentHash;

      // Display additional information
      if (mounted) {
        String publishInfo = 'Block: ${result['blockNumber'] ?? 'Pending'}\n'
            'Status: ${result['status'] ?? 'Unknown'}\n'
            'Content Hash: ${result['contentHash'] ?? contentHash}\n';

        // Update error field to show useful info
        setState(() {
          _error = null;
          _verificationResult = {
            'exists': true,
            'isVerified': true,
            'verifierCount': 0,
            'message': 'Article published! $publishInfo',
            'contentHash': result['contentHash'] ?? contentHash,
          };
        });
      }

      // Wait for transaction to complete before attempting verification
      await Future.delayed(const Duration(seconds: 3));

      // Check verification status using the content hash
      await _checkHash();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Publishing error: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyHash() async {
    if (_hashController.text.isEmpty && _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a hash or content to verify'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_privateKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your private key to verify'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _verificationResult = null;
    });

    try {
      if (!_isConnected) {
        await _blockchainService.reconnect();
        setState(() {
          _isConnected = _blockchainService.isConnected;
          _networkName = _blockchainService.networkName;
        });
      }

      if (!_isConnected) {
        throw Exception('Not connected to blockchain');
      }

      // Generate content hash if we have content but no hash
      String contentHash = _hashController.text.trim();
      final content = _contentController.text.trim();
      
      if (contentHash.isEmpty && content.isNotEmpty) {
        contentHash = _blockchainService.generateContentHash(content);
        setState(() {
          _hashController.text = contentHash;
        });
        print('Generated content hash from content: $contentHash');
      }
      
      // Get wallet address from private key
      final privateKey = _privateKeyController.text.trim();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifying on blockchain... This may take a moment.'),
            backgroundColor: Color(0xFF3498DB),
            duration: Duration(seconds: 5),
          ),
        );
      }
      
      // Simply use the verifyArticle method directly with the provided hash/content
      print('📝 Verifying using hash: $contentHash');
      final success = await _blockchainService.verifyArticle(
        privateKey: privateKey,
        contentHash: contentHash,
        content: contentHash.isEmpty ? content : null,
      );

      // Check verification status after verification attempt
      final verificationStatus = await _blockchainService.checkArticleVerification(contentHash);

      setState(() {
        _isLoading = false;
        _verificationResult = verificationStatus;
        
        // Add message about verification result
        if (success) {
          _verificationResult = {
            ..._verificationResult!,
            'message': 'Verification successful! Your signature has been added to the blockchain.',
          };
        }
      });
      
      // Show verification result to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Successfully verified article on blockchain!' : 
                      'Failed to verify. You might not be a trusted verifier or the article may not exist.'
            ),
            backgroundColor: success ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getFullDetails() async {
    if (_hashController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a hash to check'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _verificationResult = null;
    });

    try {
      if (!_isConnected) {
        await _blockchainService.reconnect();
        setState(() {
          _isConnected = _blockchainService.isConnected;
          _networkName = _blockchainService.networkName;
        });
      }

      if (!_isConnected) {
        throw Exception('Not connected to blockchain');
      }

      final hash = _hashController.text.trim();
      final result = await _blockchainService.getArticle(hash);

      setState(() {
        _isLoading = false;
        _verificationResult = result;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _checkHash() async {
    if (_hashController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!_isConnected) {
        await _blockchainService.reconnect();
        setState(() {
          _isConnected = _blockchainService.isConnected;
          _networkName = _blockchainService.networkName;
        });
      }

      if (!_isConnected) {
        throw Exception('Not connected to blockchain');
      }

      final hash = _hashController.text.trim();
      var result = await _blockchainService.checkArticleVerification(hash);

      int attemptCount = 1;
      while (!result['exists'] && attemptCount < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hash not found yet, retrying in 3 seconds (Attempt $attemptCount/3)'),
              backgroundColor: const Color(0xFFF39C12),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        await Future.delayed(const Duration(seconds: 3));
        result = await _blockchainService.checkArticleVerification(hash);
        attemptCount++;
      }

      setState(() {
        _isLoading = false;
        _verificationResult = result;
      });
      
      if (result['exists'] == true) {
        // Try to get full article details for better user information
        try {
          final fullDetails = await _blockchainService.getArticle(hash);
          if (fullDetails != null && !fullDetails.containsKey('error')) {
            setState(() {
              _verificationResult = fullDetails;
            });
          }
        } catch (e) {
          print('Could not get full article details: $e');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blockchain Hash Verification',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'CustomPoppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isConnected
                    ? const Color(0xFFE8F4FE)
                    : const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.link : Icons.link_off,
                    color: _isConnected
                        ? const Color(0xFF3498DB)
                        : const Color(0xFFF39C12),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isConnected ? 'Connected' : 'Not Connected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isConnected
                              ? const Color(0xFF3498DB)
                              : const Color(0xFFF39C12),
                          fontFamily: 'CustomPoppins',
                        ),
                      ),
                      Text(
                        'Network: $_networkName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F8C8D),
                          fontFamily: 'CustomPoppins',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!_isConnected)
                    TextButton(
                      onPressed: _isLoading ? null : _initBlockchainService,
                      child: const Text(
                        'Reconnect',
                        style: TextStyle(
                          fontFamily: 'CustomPoppins',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Option 1: Verify Content Hash',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                fontFamily: 'CustomPoppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter article content to generate its hash and verify on blockchain',
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontFamily: 'CustomPoppins',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Article Content',
                hintText: 'Paste the article content here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 4,
              style: const TextStyle(fontFamily: 'CustomPoppins'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateHash,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text(
                      'Generate Hash',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'CustomPoppins',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showPublishForm = !_showPublishForm;
                    });
                  },
                  icon: Icon(_showPublishForm ? Icons.close : Icons.upload),
                  label: Text(
                    _showPublishForm ? 'Hide Publish Form' : 'Publish to Blockchain',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'CustomPoppins',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            if (_showPublishForm) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDCE4EC),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Publish to Blockchain',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'CustomPoppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _privateKeyController,
                      decoration: InputDecoration(
                        labelText: 'Private Key (hexadecimal)',
                        hintText: '0x...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontFamily: 'CustomPoppins'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _metadataUriController,
                      decoration: InputDecoration(
                        labelText: 'Metadata URI (optional)',
                        hintText: 'news://dailyhunt/article',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(fontFamily: 'CustomPoppins'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _publishToBlockchain,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text(
                          'Publish to Blockchain',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'CustomPoppins',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Note: Publishing requires gas fees and a valid Ethereum private key.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF7F8C8D),
                        fontFamily: 'CustomPoppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Option 2: Verify Existing Hash',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                fontFamily: 'CustomPoppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a hash directly to check if it exists on the blockchain',
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontFamily: 'CustomPoppins',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hashController,
              decoration: InputDecoration(
                labelText: 'Content Hash',
                hintText: '0x...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _hashController.text = data!.text!;
                    }
                  },
                  tooltip: 'Paste from clipboard',
                ),
              ),
              style: const TextStyle(fontFamily: 'CustomPoppins'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _verifyHash,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text(
                      'Check Verification',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'CustomPoppins',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getFullDetails,
                    icon: const Icon(Icons.info_outline),
                    label: const Text(
                      'Get Full Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'CustomPoppins',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF2C3E50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Checking blockchain...',
                      style: TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontFamily: 'CustomPoppins',
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEECEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error_outline, color: Color(0xFFE74C3C)),
                        SizedBox(width: 8),
                        Text(
                          'Error',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE74C3C),
                            fontFamily: 'CustomPoppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontFamily: 'CustomPoppins',
                      ),
                    ),
                  ],
                ),
              ),
            if (_verificationResult != null && !_isLoading)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _verificationResult!.containsKey('error')
                      ? const Color(0xFFFFF9EC)
                      : (_verificationResult!['exists'] == true
                          ? const Color(0xFFE8F8F5)
                          : const Color(0xFFF8F9FA)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _verificationResult!.containsKey('error')
                        ? const Color(0xFFF39C12)
                        : (_verificationResult!['exists'] == true
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFBDC3C7)),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _verificationResult!.containsKey('error')
                              ? Icons.warning_amber_rounded
                              : (_verificationResult!['exists'] == true
                                  ? Icons.verified_rounded
                                  : Icons.help_outline),
                          color: _verificationResult!.containsKey('error')
                              ? const Color(0xFFF39C12)
                              : (_verificationResult!['exists'] == true
                                  ? const Color(0xFF2ECC71)
                                  : const Color(0xFF7F8C8D)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _verificationResult!.containsKey('error')
                              ? 'Error Getting Details'
                              : (_verificationResult!['exists'] == true
                                  ? 'Hash Found on Blockchain'
                                  : 'Hash Not Found'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _verificationResult!.containsKey('error')
                                ? const Color(0xFFF39C12)
                                : (_verificationResult!['exists'] == true
                                    ? const Color(0xFF2ECC71)
                                    : const Color(0xFF7F8C8D)),
                            fontFamily: 'CustomPoppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_verificationResult!.containsKey('error'))
                      Text(
                        'Error: ${_verificationResult!['error']}',
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontFamily: 'CustomPoppins',
                        ),
                      ),
                    if (_verificationResult!['exists'] == true)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResultRow(
                            'Verified',
                            _verificationResult!['isVerified'] == true
                                ? 'Yes'
                                : 'No',
                          ),
                          _buildResultRow(
                            'Verifier Count',
                            _verificationResult!['verifierCount'].toString(),
                          ),
                          if (_verificationResult!.containsKey('publisher'))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text(
                                  'Full Article Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                    fontFamily: 'CustomPoppins',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildResultRow(
                                  'Publisher',
                                  _verificationResult!['publisher'],
                                ),
                                _buildResultRow(
                                  'Published At',
                                  _formatTimestamp(
                                      _verificationResult!['timestamp']),
                                ),
                                if (_verificationResult!
                                    .containsKey('metadataURI'))
                                  _buildResultRow(
                                    'Metadata URI',
                                    _verificationResult!['metadataURI'],
                                  ),
                              ],
                            ),
                        ],
                      ),
                    if (_verificationResult!['exists'] == false &&
                        !_verificationResult!.containsKey('error'))
                      const Text(
                        'This hash was not found on the blockchain. It may not have been published or verified yet.',
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontFamily: 'CustomPoppins',
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Network: ${_verificationResult!['networkName'] ?? _networkName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF7F8C8D),
                        fontFamily: 'CustomPoppins',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
                fontFamily: 'CustomPoppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontFamily: 'CustomPoppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}