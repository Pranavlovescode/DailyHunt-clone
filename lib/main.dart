import 'package:dailyhunt/firebase_options.dart';
import 'package:dailyhunt/home.dart';
import 'package:dailyhunt/languages.dart';
import 'package:dailyhunt/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:dailyhunt/login.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isLoggedIn = (await AuthService.isUserLoggedIn()) ?? false;
  bool showOnboarding = (await shouldShowOnboarding()) ?? true;

  print("isLoggedIn: $isLoggedIn, showOnboarding: $showOnboarding");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
    );
    print("✅ Firebase connected successfully!");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }
  runApp(MyApp(isLoggedIn: isLoggedIn, showOnboarding: showOnboarding));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn,required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "The Daily Globe",
      theme: ThemeData(
        primaryColor: const Color(0xFF2C3E50),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: const ColorScheme(
          primary: Color(0xFF3498DB),
          secondary: Color(0xFF2ECC71),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFF8F9FA),
          error: Color(0xFFE74C3C),
          onPrimary: Color(0xFFFFFFFF),
          onSecondary: Color(0xFFFFFFFF),
          onSurface: Color(0xFF2C3E50),
          onBackground: Color(0xFF2C3E50),
          onError: Color(0xFFFFFFFF),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF2C3E50),
            fontFamily: "CustomPoppins",
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF2C3E50),
            fontFamily: "CustomPoppins",
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF2C3E50),
            fontFamily: "CustomPoppins",
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498DB),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: isLoggedIn
        ? Home(lang: "en")
        : (showOnboarding ? const OnboardingFlow() : const Login()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: const [
                  SplashScreen(),
                  TrackingScreen(),
                  NotificationScreen(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3498DB),
                      ),
                      child: const Text(
                        "Back",
                        style: TextStyle(
                          fontFamily: "CustomPoppins",
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  ElevatedButton(
                    onPressed: () async {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        await completeOnboarding();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 45),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == 2 ? "Get Started" : "Next",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: "CustomPoppins",
                      ),
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
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3498DB).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.public,
                size: 80,
                color: Color(0xFF3498DB),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'THE DAILY GLOBE',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: "CustomPoppins",
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Window to the World',
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 18,
                fontFamily: "CustomPoppins",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to\nThe Daily Globe!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: "CustomPoppins",
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please set your preferences to\nget the app up and running.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 16,
                fontFamily: "CustomPoppins",
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3498DB).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This publication is\nad-supported.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: "CustomPoppins",
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enable ad tracking to see personalized advertising that is relevant to your interests.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: "CustomPoppins",
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3498DB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Personalize My Ads',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: "CustomPoppins",
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'No Thanks',
                        style: TextStyle(
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
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Future<void> requestNotificationPermission(BuildContext context) async {
    var status = await Permission.notification.request();

    if (status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission granted!'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
      }
    } else if (status.isDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission denied!'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission permanently denied. Enable from settings.'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
      }
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Stay Connected with\nThe Daily Globe!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: "CustomPoppins",
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Never miss important updates\nand breaking news.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7F8C8D),
                fontSize: 16,
                fontFamily: "CustomPoppins",
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2ECC71).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Don't Miss Our\nTop Stories!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: "CustomPoppins",
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Subscribe to our notifications to stay up to date on the latest breaking news.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: "CustomPoppins",
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => requestNotificationPermission(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2ECC71),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Enable Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: "CustomPoppins",
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Maybe Later',
                        style: TextStyle(
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
      ),
    );
  }
}

Future<bool> isUserLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('showOnboarding') ?? true;
}

Future<void> completeOnboarding() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('showOnboarding', false);
}

