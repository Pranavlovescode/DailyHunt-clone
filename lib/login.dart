import 'package:dailyhunt/languages.dart';
import 'package:dailyhunt/services/auth_service.dart';
import 'package:dailyhunt/signup_page.dart';
import 'package:flutter/material.dart';
import 'home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final int flag = 0;

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

          // Skip Button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () {
                debugPrint("Skipped");
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const Languages();
                }));
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2C3E50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Skip",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: "CustomPoppins",
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward, size: 24),
                ],
              ),
            ),
          ),

          // App Logo and Title
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.public,
                    size: 72,
                    color: Color(0xFF3498DB),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'THE DAILY GLOBE',
                  style: TextStyle(
                    color: Color(0xFF2C3E50),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: "CustomPoppins",
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // Login Card
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
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                      fontFamily: "CustomPoppins",
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Login to your account",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7F8C8D),
                      fontFamily: "CustomPoppins",
                    ),
                  ),
                  const SizedBox(height: 32),

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
                  const SizedBox(height: 24),

                  // Login Button
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
                      onPressed: () async {
                        AuthService().login(
                          email: emailController.text,
                          password: passwordController.text,
                          context: context,
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: "CustomPoppins",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Forgot Password
                  TextButton(
                    onPressed: () {
                      // TODO: Implement Forgot Password Logic
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7F8C8D),
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        fontFamily: "CustomPoppins",
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Sign Up Link
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
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
