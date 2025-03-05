import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyhunt/home.dart';
import 'package:dailyhunt/services/user_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  String name = "";
  String email = "";
  bool isLoading = true;

  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
    {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        
        if (mounted) {
          setState(() {
            name = doc['name'] ?? '';
            email = doc['email'] ?? '';
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint("Error loading user data: $e");
    }
  }

  void _selectLanguage(String code, String languageName) async {
    try {
      await UserPreferences.saveUserInfo(name, email, languageName);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home(lang: code)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save language preference'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE8F6FF)],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3498DB),
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF3498DB).withOpacity(0.1),
                            ),
                            child: const Icon(
                              Icons.language,
                              size: 48,
                              color: Color(0xFF3498DB),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Choose Your Language',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                              fontFamily: "CustomPoppins",
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select your preferred language for news content',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF7F8C8D),
                              fontFamily: "CustomPoppins",
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Language Grid
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: languages.length,
                          itemBuilder: (context, index) {
                            final language = languages[index];
                            return InkWell(
                              onTap: () => _selectLanguage(
                                language['code']!,
                                language['name']!,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF3498DB).withOpacity(0.1),
                                      const Color(0xFF3498DB).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF3498DB).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      language['native']!,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                        fontFamily: "CustomPoppins",
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      language['name']!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF7F8C8D),
                                        fontFamily: "CustomPoppins",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
