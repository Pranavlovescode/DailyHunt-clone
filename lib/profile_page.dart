import 'package:dailyhunt/edit_profile_page.dart';
import 'package:dailyhunt/home.dart';
import 'package:dailyhunt/languages.dart';
import 'package:dailyhunt/services/auth_service.dart';
import 'package:dailyhunt/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String profileImageUrl = "https://i.pravatar.cc/150?img=10";
  String name = "";
  String email = "";
  String language = "";
  bool isLoading = true;
  final List<String> languages = ["English", "Spanish", "French", "Hindi"];
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get user profile from FirestoreService
      final userData = await _firestoreService.getUserProfile();
      
      // Get language preference from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('userLanguage') ?? "English";
      
      setState(() {
        name = userData['name'] ?? "Guest";
        email = userData['email'] ?? "No email";
        language = savedLanguage;
        
        // Update profile image if available
        if (userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty) {
          profileImageUrl = userData['photoUrl'];
        }
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading user info: $e");
    }
  }

  Future<void> _updateLanguage(String newLanguage) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userLanguage', newLanguage);
      setState(() => language = newLanguage);
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error updating language: $e");
    }
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Language",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "CustomPoppins",
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) => ListTile(
                leading: Icon(
                  Icons.language,
                  color: language == lang
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF7F8C8D),
                ),
                title: Text(
                  lang,
                  style: TextStyle(
                    fontFamily: "CustomPoppins",
                    color: language == lang
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF2C3E50),
                    fontWeight: language == lang
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: language == lang
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => _updateLanguage(lang),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8F9FA), Color(0xFFE8F6FF)],
        ),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              backgroundImage: NetworkImage(profileImageUrl),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                            fontFamily: "CustomPoppins",
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                            fontFamily: "CustomPoppins",
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.language,
                          title: "Language",
                          subtitle: language,
                          onTap: ()=>{
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Languages()))
                          },
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.notifications_outlined,
                          title: "Notifications",
                          subtitle: "Manage notifications",
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: "Privacy",
                          subtitle: "Manage privacy settings",
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: "CustomPoppins",
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => AuthService().logout(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                                width: 1.5,
                              ),
                            ),
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: "CustomPoppins",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
          fontFamily: "CustomPoppins",
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF7F8C8D),
          fontFamily: "CustomPoppins",
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap,
    );
  }
}
