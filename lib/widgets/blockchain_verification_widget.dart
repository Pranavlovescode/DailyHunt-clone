import 'package:flutter/material.dart';
import 'package:dailyhunt/services/blockchain_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockchainVerificationWidget extends StatefulWidget {
  final String articleContent;
  final String articleId;

  const BlockchainVerificationWidget({
    Key? key,
    required this.articleContent,
    this.articleId = '',
  }) : super(key: key);

  @override
  State<BlockchainVerificationWidget> createState() => _BlockchainVerificationWidgetState();
}

class _BlockchainVerificationWidgetState extends State<BlockchainVerificationWidget> {
  bool _isLoading = true;
  bool _isVerified = false;
  int _verifierCount = 0;
  bool _exists = false;
  bool _serviceAvailable = true; // Flag to track if blockchain service is available
  bool _isConnected = false; // Flag to track if connected to a blockchain node
  String _networkName = ""; // Current blockchain network name
  String? _error;
  final BlockchainService _blockchainService = BlockchainService();
  late String _articleId; // Store the article ID for persistence

  @override
  void initState() {
    super.initState();
    _determineArticleId();
    _checkVerification();
  }

  // Determine the article ID for persistence
  void _determineArticleId() {
    _articleId = widget.articleId;
    if (_articleId.isEmpty) {
      _articleId = _blockchainService.generateContentHash(widget.articleContent);
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First check if we have a saved verification status
      final prefs = await SharedPreferences.getInstance();
      final verificationKey = 'article_verified_${_articleId}';
      final verifierCountKey = 'article_verifier_count_${_articleId}';
      final existsKey = 'article_exists_${_articleId}';

      final savedIsVerified = prefs.getBool(verificationKey);
      final savedVerifierCount = prefs.getInt(verifierCountKey);
      final savedExists = prefs.getBool(existsKey);

      // If we have saved verification status, use that
      if (savedIsVerified != null && savedExists != null) {
        setState(() {
          _isVerified = savedIsVerified;
          _verifierCount = savedVerifierCount ?? 0;
          _exists = savedExists;
          _isLoading = false;
          _isConnected = true; // Consider connected for UI purposes
          _networkName = "Local"; // Show as locally verified
        });
        return;
      }

      // Try to initialize the blockchain service
      final initialized = await _blockchainService.ensureInitialized();
      final isConnected = _blockchainService.isConnected;

      if (!initialized) {
        setState(() {
          _isLoading = false;
          _serviceAvailable = false;
          _isConnected = false;
          _error = 'Blockchain service is not available';
        });
        return;
      }

      if (!isConnected) {
        setState(() {
          _isLoading = false;
          _isConnected = false;
          _networkName = "Not Connected";
          _error = 'No connection to blockchain network';
        });
        return;
      }

      // Service is initialized and connected
      _networkName = _blockchainService.networkName;

      final verification = await _blockchainService.checkArticleVerification(_articleId);

      setState(() {
        _isLoading = false;
        _exists = verification['exists'] ?? false;
        _isVerified = verification['isVerified'] ?? false;
        _verifierCount = verification['verifierCount'] ?? 0;
        _isConnected = true;
        _networkName = verification['networkName'] ?? _blockchainService.networkName;
        _error = verification['error'];
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _serviceAvailable = false;
        _isConnected = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _reconnect() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _blockchainService.reconnect();

      if (success) {
        await _checkVerification();
      } else {
        setState(() {
          _isLoading = false;
          _isConnected = false;
          _networkName = "Not Connected";
          _error = 'Failed to reconnect to blockchain network';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
        _error = 'Reconnection error: ${e.toString()}';
      });
    }
  }

  // Save verification state to SharedPreferences
  Future<void> _saveVerificationStatus({
    required bool isVerified,
    required int verifierCount,
    required bool exists,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save verification state
      await prefs.setBool('article_verified_${_articleId}', isVerified);
      await prefs.setInt('article_verifier_count_${_articleId}', verifierCount);
      await prefs.setBool('article_exists_${_articleId}', exists);

      print("✅ Saved verification status for article: $_articleId");
    } catch (e) {
      print("❌ Failed to save verification status: $e");
    }
  }

  Future<void> _verifyArticle() async {
    // Show a confirmation dialog first
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'Verify This Article',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'CustomPoppins',
              ),
            ),
            content: const Text(
              'Do you want to verify this article as legitimate news? Your verification helps others trust this content.',
              style: TextStyle(
                fontFamily: 'CustomPoppins',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontFamily: 'CustomPoppins',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                ),
                child: const Text(
                  'Verify Article',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'CustomPoppins',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Update verification status
      setState(() {
        _isLoading = false;
        _isVerified = true;
        _verifierCount += 1;
        _exists = true;
      });

      // Save verification status to SharedPreferences
      await _saveVerificationStatus(
        isVerified: _isVerified,
        verifierCount: _verifierCount,
        exists: _exists,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article verified successfully! Thank you for contributing.'),
            backgroundColor: Color(0xFF2ECC71),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Note: In a real implementation, you would actually call a Firebase function
      // or other backend service to record the verification. Here's how that might look:
      //
      // await FirebaseFirestore.instance.collection('article_verifications').add({
      //   'articleId': _articleId,
      //   'articleContent': widget.articleContent,
      //   'verifiedAt': DateTime.now(),
      //   'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
      // });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Verification failed: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFE74C3C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _getBackgroundColor(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoading
          ? const _LoadingState()
          : !_serviceAvailable
              ? _ServiceUnavailableState(onRetry: _checkVerification)
              : !_isConnected
                  ? _NoConnectionState(
                      networkName: _networkName,
                      onRetry: _reconnect,
                      error: _error,
                    )
                  : _error != null
                      ? _ErrorState(error: _error!, onRetry: _checkVerification)
                      : _exists
                          ? _VerifiedState(
                              isVerified: _isVerified,
                              verifierCount: _verifierCount,
                              networkName: _networkName,
                              onVerify: _verifyArticle,
                            )
                          : _NotOnBlockchainState(
                              networkName: _networkName,
                              onVerify: _verifyArticle,
                            ),
    );
  }

  Color _getBackgroundColor() {
    if (_isLoading) return Colors.white;
    if (!_serviceAvailable) return Colors.white;
    if (!_isConnected) return const Color(0xFFFFF9EC); // Light yellow for no connection
    if (_error != null) return const Color(0xFFFEF0F0); // Light red
    if (!_exists) return Colors.white;
    return _isVerified
        ? const Color(0xFFECF9F2) // Light green
        : const Color(0xFFFFF9EC); // Light yellow
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
          ),
        ),
        SizedBox(width: 12),
        Text(
          'Checking blockchain verification...',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'CustomPoppins',
            color: Color(0xFF7F8C8D),
          ),
        ),
      ],
    );
  }
}

class _ServiceUnavailableState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ServiceUnavailableState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF7F8C8D)),
            const SizedBox(width: 8),
            const Text(
              'Blockchain Verification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'CustomPoppins',
                color: Color(0xFF7F8C8D),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF3498DB)),
              onPressed: onRetry,
              tooltip: 'Retry verification',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Blockchain verification service is temporarily unavailable.',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'CustomPoppins',
            color: Color(0xFF7F8C8D),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE74C3C)),
            const SizedBox(width: 8),
            const Text(
              'Verification Error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'CustomPoppins',
                color: Color(0xFFE74C3C),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF3498DB)),
              onPressed: onRetry,
              tooltip: 'Retry verification',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Could not verify this article on blockchain. Please try again later.',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'CustomPoppins',
            color: Color(0xFF7F8C8D),
          ),
        ),
      ],
    );
  }
}

class _NoConnectionState extends StatelessWidget {
  final String networkName;
  final VoidCallback onRetry;
  final String? error;

  const _NoConnectionState({
    required this.networkName,
    required this.onRetry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud_off, color: Color(0xFFF39C12)), // Yellow warning icon
            const SizedBox(width: 8),
            const Text(
              'Not Connected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'CustomPoppins',
                color: Color(0xFFF39C12),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF3498DB)),
              onPressed: onRetry,
              tooltip: 'Reconnect',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'No connection to blockchain network. '
          'Verification status cannot be determined.',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'CustomPoppins',
            color: Color(0xFF2C3E50),
          ),
        ),
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!.length > 100 ? '${error!.substring(0, 100)}...' : error!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontFamily: 'CustomPoppins',
                color: Color(0xFF7F8C8D),
              ),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Try reconnecting'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498DB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(
              fontFamily: 'CustomPoppins',
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerifiedState extends StatelessWidget {
  final bool isVerified;
  final int verifierCount;
  final String networkName;
  final VoidCallback onVerify;

  const _VerifiedState({
    required this.isVerified,
    required this.verifierCount,
    required this.networkName,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isVerified ? Icons.verified_user : Icons.pending,
              color: isVerified ? const Color(0xFF2ECC71) : const Color(0xFFF39C12),
            ),
            const SizedBox(width: 8),
            Text(
              isVerified ? 'Blockchain Verified' : 'Pending Verification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'CustomPoppins',
                color: isVerified ? const Color(0xFF2ECC71) : const Color(0xFFF39C12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isVerified
              ? 'This article has been verified on the blockchain by $verifierCount ${verifierCount == 1 ? 'verifier' : 'verifiers'}.'
              : 'This article exists on the blockchain but needs more verification.',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'CustomPoppins',
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Network: $networkName',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            fontFamily: 'CustomPoppins',
            color: Color(0xFF7F8C8D),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onVerify,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text(
            'Verify Article',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'CustomPoppins',
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isVerified ? const Color(0xFF2ECC71) : const Color(0xFFF39C12),
            side: BorderSide(
              color: isVerified ? const Color(0xFF2ECC71) : const Color(0xFFF39C12),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class _NotOnBlockchainState extends StatelessWidget {
  final String networkName;
  final VoidCallback onVerify;

  const _NotOnBlockchainState({
    required this.networkName,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF7F8C8D)),
            SizedBox(width: 8),
            Text(
              'Not Yet Verified',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'CustomPoppins',
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'This article has not been verified yet. You can help verify this content as accurate.',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'CustomPoppins',
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Network: $networkName',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            fontFamily: 'CustomPoppins',
            color: Color(0xFF7F8C8D),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onVerify,
          icon: const Icon(Icons.verified_outlined),
          label: const Text(
            'Verify this article',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'CustomPoppins',
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3498DB),
            side: const BorderSide(
              color: Color(0xFF3498DB),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}