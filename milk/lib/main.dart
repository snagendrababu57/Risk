import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:milk/screens/login_age.dart';
import 'package:milk/pages/admin_page.dart'; // Import Admin Dashboard
import 'package:milk/pages/student_page.dart'; // Import Student Dashboard
import 'firebase_options.dart'; // Ensure this file is generated

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseConnected;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseConnected = true;
  } catch (e) {
    firebaseConnected = false;
  }

  runApp(MyApp(firebaseConnected: firebaseConnected));
}

class MyApp extends StatelessWidget {
  final bool firebaseConnected;

  const MyApp({super.key, required this.firebaseConnected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Milk',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(firebaseConnected: firebaseConnected),
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  final bool firebaseConnected;

  const SplashScreen({super.key, required this.firebaseConnected});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is already logged in, fetch role and navigate
      String role = await getUserRole(user.uid);
      if (mounted) {
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      LoginPage(firebaseConnected: widget.firebaseConnected),
            ),
          );
        }
      }
    } else {
      // If no user, navigate to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    LoginPage(firebaseConnected: widget.firebaseConnected),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.jpeg', // Ensure this path is correct
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}

// Fetch user role from Firebase Database
Future<String> getUserRole(String uid) async {
  try {
    final snapshot = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data['role'] as String? ?? 'unknown';
    }
  } catch (e) {
    print('Error fetching role: $e');
  }
  return 'unknown';
}

// Logout Function
void logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => const LoginPage(firebaseConnected: true),
    ),
    (route) => false,
  );
}
