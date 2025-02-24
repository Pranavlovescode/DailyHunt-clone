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
    // await Firebase.initializeApp(
    //   options: FirebaseOptions(
    //     apiKey: 'AIzaSyBpVLoaXlXO4fMcQFCIj26smZp49IPpVow',
    //     appId: '1:246713456730:android:b351717556972c1b9a2063',
    //     messagingSenderId: '246713456730',
    //     projectId: 'dailyhunt-30290',
    //     storageBucket: 'dailyhunt-30290.firebasestorage.app',
    //   )
    // );
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
      color: Color(0xFF001A6E),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE1FFBB),
        // textTheme: const TextTheme(
        //   bodyLarge: TextStyle(color: Color(0xFFEFE9D5)),
        //   bodyMedium: TextStyle(color: Color(0xFFEFE9D5)),
        //   titleLarge: TextStyle(color: Color(0xFFEFE9D5)),
        // ),
        // textTheme: const TextTheme(
        //   titleLarge:TextStyle(
        //     color: Color(0xFFEFE9D5)
        //   )
        // )
      ),
      home: isLoggedIn
        ? Home(lang: "en")
        : (showOnboarding ? OnboardingFlow() : Login()),
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
      body: Column(
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
          // Page Navigation Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                    child: const Text(
                      "Back",
                      style: TextStyle(
                          color: Color(0xFF001A6E),
                          fontFamily: "CustomPoppins"),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () async {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Navigate to login screen
                      await completeOnboarding();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Color(0xFF001A6E),
                    backgroundColor: Color(0xFF009990),
                  ),
                  child: Text(_currentPage == 2 ? "Get Started" : "Next"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'THE DAILY GLOBE',
        style: TextStyle(
            color: Color(0xFF001A6E),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: "CustomPoppins"),
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
                  color: Color(0xFF001A6E),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "CustomPoppins"),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please set your preferences to\nget the app up and running.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF001A6E),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFFB8E8E0),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This publication is\nad-supported.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: "CustomPoppins"),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enable ad tracking to see personalized advertising that is relevant to your interests.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: "CustomPoppins"),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF074799),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Personalize My Ads',
                        style: TextStyle(
                          color: Color(0xFFE1FFBB),
                          fontFamily: "CustomPoppins",
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        print('No Thanks');
                      },
                      child: const Text(
                        'No Thanks',
                        style: TextStyle(color: Colors.black54),
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
      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission granted!')),
      );
    } else if (status.isDenied) {
      // Show warning message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission denied!')),
      );
    } else if (status.isPermanentlyDenied) {
      // Open app settings if permanently denied
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Notification permission permanently denied. Enable from settings.'),
        ),
      );
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
              'Welcome to\nThe Daily Globe!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF001A6E),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: "CustomPoppins"),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please set your preferences to\nget the app up and running.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF001A6E),
                  fontSize: 16,
                  fontFamily: "CustomPoppins"),
            ),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFFB8E8E0),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Don't miss our\ntop stories!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: "CustomPoppins"),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Subscribe to our notifications to stay up to date on the latest breaking news.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: "CustomPoppins"),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => requestNotificationPermission(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF074799),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Subscribe to Notifications Now',
                        style: TextStyle(
                            color: Color(0xFFE1FFBB),
                            fontFamily: "CustomPoppins"),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'No Thanks',
                        style: TextStyle(
                            color: Colors.black54, fontFamily: "CustomPoppins"),
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
return prefs.getBool('isLoggedIn') ?? false; // Ensure it never returns null
}


/// Check if onboarding has been completed
Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('showOnboarding') ?? true; // Default to true
}

Future<void> completeOnboarding() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool('showOnboarding', false); // Save preference
}
