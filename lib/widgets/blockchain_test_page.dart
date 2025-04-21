import 'package:flutter/material.dart';
import 'package:dailyhunt/services/blockchain_service.dart';

class BlockchainTestPage extends StatefulWidget {
  const BlockchainTestPage({Key? key}) : super(key: key);

  @override
  _BlockchainTestPageState createState() => _BlockchainTestPageState();
}

class _BlockchainTestPageState extends State<BlockchainTestPage> {
  final BlockchainService _blockchainService = BlockchainService();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _metadataController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _articleIdController = TextEditingController();
  
  bool _isLoading = false;
  String _statusMessage = '';
  String _lastPublishedArticleId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing blockchain service...';
    });

    try {
      final initialized = await _blockchainService.ensureInitialized();
      setState(() {
        _isLoading = false;
        _statusMessage = initialized 
            ? 'Blockchain service initialized successfully!'
            : 'Failed to initialize blockchain service';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _publishArticle() async {
    if (_contentController.text.isEmpty || _privateKeyController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter content and private key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Publishing article to blockchain...';
    });

    try {
      final txHash = await _blockchainService.publishArticle(
        privateKey: _privateKeyController.text,
        content: _contentController.text,
        metadataUri: _metadataController.text.isNotEmpty 
            ? _metadataController.text 
            : 'ipfs://default-metadata',
      );

      setState(() {
        _isLoading = false;
        _statusMessage = txHash != null 
            ? 'Article published successfully! Transaction: ${txHash.substring(0, 10)}...'
            : 'Failed to publish article';
            
        // Generate articleId from content for testing
        _lastPublishedArticleId = _blockchainService.generateContentHash(_contentController.text);
        _articleIdController.text = _lastPublishedArticleId;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error publishing article: $e';
      });
    }
  }

  Future<void> _verifyArticle() async {
    if (_articleIdController.text.isEmpty || _privateKeyController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter article ID and private key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Verifying article...';
    });

    try {
      final success = await _blockchainService.verifyArticle(
        privateKey: _privateKeyController.text,
        articleId: _articleIdController.text,
      );

      setState(() {
        _isLoading = false;
        _statusMessage = success 
            ? 'Article verified successfully!'
            : 'Failed to verify article';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error verifying article: $e';
      });
    }
  }

  Future<void> _checkVerificationStatus() async {
    if (_articleIdController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter an article ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking verification status...';
    });

    try {
      final status = await _blockchainService.checkArticleVerification(_articleIdController.text);

      setState(() {
        _isLoading = false;
        if (status.containsKey('error')) {
          _statusMessage = 'Error: ${status['error']}';
        } else {
          _statusMessage = 'Article exists: ${status['exists']}, '
              'Verified: ${status['isVerified']}, '
              'Verifier count: ${status['verifierCount']}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error checking status: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blockchain Verification Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Credentials',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _privateKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Private Key',
                        hintText: '0x...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Publish Article',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Article Content',
                        hintText: 'Enter article content here',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _metadataController,
                      decoration: const InputDecoration(
                        labelText: 'Metadata URI (Optional)',
                        hintText: 'ipfs://...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _publishArticle,
                      child: const Text('Publish Article'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify Article',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _articleIdController,
                      decoration: const InputDecoration(
                        labelText: 'Article ID',
                        hintText: '0x...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyArticle,
                          child: const Text('Verify Article'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _checkVerificationStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                          ),
                          child: const Text('Check Status'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    _metadataController.dispose();
    _privateKeyController.dispose();
    _articleIdController.dispose();
    super.dispose();
  }
}