import 'package:dailyhunt/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static Future<void> saveUserInfo(String name, String email, String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    await prefs.setString('userLanguage', language);
  }

  static Future<Map<String, String>> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('userName') ?? 'Guest',
      'email': prefs.getString('userEmail') ?? 'No email',
      'language': prefs.getString('userLanguage') ?? 'English',
    };
  }

  static Future<void> updateLanguage(String language,BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userLanguage', language);
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Home(lang: language);
    }));
  }
}
