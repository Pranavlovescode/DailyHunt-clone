import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyhunt/languages.dart';
import 'package:dailyhunt/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = "isLoggedIn";

  /// Save login state
  Future<void> _saveLoginState(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Login method
  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("Login Successful");
      await _saveLoginState(true);

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return Languages();
      }));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful")),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Failed with error code: ${e.code}');
      debugPrint(e.message);
      if (e.code == 'invalid-credential') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email or Password is incorrect")),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  /// Signup method
  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required BuildContext context,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).set({
        "name": name,
        "email": email,
        "password": password,
      });
      debugPrint("Signup Successful");
      await _saveLoginState(true);

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return Languages();
      }));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup Successful")),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Failed with error code: ${e.code}');
      debugPrint(e.message);
      if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email already in use")),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  /// Logout method
  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      debugPrint("Logout Successful");

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
        return Login();
      }));
    } catch (e) {
      debugPrint("Logout Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to log out. Please try again.")),
      );
    }
  }
}
