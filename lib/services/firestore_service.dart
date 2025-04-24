import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  
  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  // Get current user profile data with caching for offline use
  Future<Map<String, dynamic>> getUserProfile() async {
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return {'name': 'Guest', 'email': '', 'photoUrl': null};
    }
    
    try {
      // Try to load from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_name');
      final cachedEmail = prefs.getString('user_email');
      final cachedPhotoUrl = prefs.getString('user_photo_url');
      
      // Try to fetch fresh data from Firestore
      try {
        final docSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          
          // Cache the data for offline use
          await prefs.setString('user_name', data['name'] ?? currentUser.displayName ?? 'Guest');
          await prefs.setString('user_email', data['email'] ?? currentUser.email ?? '');
          if (data['photoUrl'] != null) {
            await prefs.setString('user_photo_url', data['photoUrl']);
          }
          
          return {
            'name': data['name'] ?? currentUser.displayName ?? 'Guest',
            'email': data['email'] ?? currentUser.email ?? '',
            'photoUrl': data['photoUrl'],
          };
        }
      } catch (e) {
        print("Error fetching user profile from Firestore: $e");
        // Continue to use cached data
      }
      
      // If we have cached data, use that
      if (cachedName != null) {
        return {
          'name': cachedName,
          'email': cachedEmail ?? currentUser.email ?? '',
          'photoUrl': cachedPhotoUrl,
        };
      }
      
      // Use Firebase Auth data as fallback
      return {
        'name': currentUser.displayName ?? 'User',
        'email': currentUser.email ?? '',
        'photoUrl': currentUser.photoURL,
      };
    } catch (e) {
      print("Error in getUserProfile: $e");
      return {
        'name': currentUser.displayName ?? 'User',
        'email': currentUser.email ?? '',
        'photoUrl': null,
      };
    }
  }

  // Save user profile data - will attempt Firestore, but always caches locally
  Future<bool> saveUserProfile(Map<String, dynamic> profileData) async {
    final User? currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return false;
    }

    // Always save to local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      if (profileData.containsKey('name')) {
        await prefs.setString('user_name', profileData['name']);
      }
      if (profileData.containsKey('email')) {
        await prefs.setString('user_email', profileData['email']);
      }
      if (profileData.containsKey('photoUrl') && profileData['photoUrl'] != null) {
        await prefs.setString('user_photo_url', profileData['photoUrl']);
      }
    } catch (e) {
      print("Error caching user profile: $e");
    }
    
    // Try to save to Firestore
    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(profileData, SetOptions(merge: true));
      return true;
    } catch (e) {
      print("Error saving user profile to Firestore: $e");
      // Return true anyway since we saved to local cache
      return true;
    }
  }

  // Record article verification - works offline with SharedPreferences
  Future<bool> verifyArticle(String articleId, String articleContent) async {
    final User? currentUser = _auth.currentUser;
    final userId = currentUser?.uid ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    try {
      // Save verification to Firestore if possible
      try {
        await _firestore.collection('article_verifications').add({
          'articleId': articleId,
          'articleContent': articleContent,
          'verifiedAt': timestamp,
          'userId': userId,
        });
      } catch (e) {
        print("Error saving verification to Firestore: $e");
        // Continue to local storage
      }
      
      // Always save locally
      final prefs = await SharedPreferences.getInstance();
      final verifiedArticles = prefs.getStringList('verified_articles') ?? [];
      
      if (!verifiedArticles.contains(articleId)) {
        verifiedArticles.add(articleId);
        await prefs.setStringList('verified_articles', verifiedArticles);
      }
      
      // Store verification count
      final verifierCountKey = 'article_verifier_count_$articleId';
      final currentCount = prefs.getInt(verifierCountKey) ?? 0;
      await prefs.setInt(verifierCountKey, currentCount + 1);
      
      return true;
    } catch (e) {
      print("Error verifying article: $e");
      return false;
    }
  }

  // Check if an article has been verified by the current user
  Future<bool> isArticleVerifiedByUser(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final verifiedArticles = prefs.getStringList('verified_articles') ?? [];
      return verifiedArticles.contains(articleId);
    } catch (e) {
      print("Error checking article verification: $e");
      return false;
    }
  }

  // Get all verified articles by the current user
  Future<List<String>> getVerifiedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('verified_articles') ?? [];
    } catch (e) {
      print("Error getting verified articles: $e");
      return [];
    }
  }
}