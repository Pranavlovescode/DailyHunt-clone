import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyhunt/languages.dart';
import 'package:dailyhunt/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:dailyhunt/login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F9FA), Color(0xFFE8F6FF)],
              ),
            ),
          ),

          // App Logo and Title
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.public,
                    size: 60,
                    color: Color(0xFF3498DB),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: "CustomPoppins",
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join The Daily Globe community',
                  style: TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 16,
                    fontFamily: "CustomPoppins",
                  ),
                ),
              ],
            ),
          ),

          // Signup Form
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name Field
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      labelStyle: const TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontFamily: "CustomPoppins",
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xFF3498DB),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF3498DB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: const TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontFamily: "CustomPoppins",
                      ),
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Color(0xFF3498DB),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF3498DB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontFamily: "CustomPoppins",
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFF3498DB),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF3498DB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      labelStyle: const TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontFamily: "CustomPoppins",
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF3498DB),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF3498DB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498DB),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        if (passwordController.text == confirmPasswordController.text) {
                          AuthService().signup(
                            email: emailController.text,
                            password: passwordController.text,
                            name: nameController.text,
                            context: context,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Passwords do not match'),
                              backgroundColor: Color(0xFFE74C3C),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: "CustomPoppins",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Link
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3498DB),
                        fontWeight: FontWeight.w600,
                        fontFamily: "CustomPoppins",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
