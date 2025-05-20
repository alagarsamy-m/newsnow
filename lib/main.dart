import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:news_app/firebase_options.dart';
import 'package:news_app/screens/login_screen.dart';
import 'package:news_app/screens/admin_screen.dart';
import 'package:news_app/screens/user_screen.dart';
import 'package:news_app/screens/splash_screen.dart';
import 'package:news_app/screens/subscription_prompt_screen.dart';
import 'package:news_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  bool _showSplash = true;
  bool _hasSubscriptions = false;
  bool _checkingSubscriptions = false;

  @override
  void initState() {
    super.initState();
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        setState(() {
          _isLoggedIn = true;
          _isAdmin = user.email == 'admin@example.com'; // Simple admin check
          _checkingSubscriptions = true;
        });
        if (!_isAdmin) {
          _firestore.collection('subscriptions').doc(user.uid).snapshots().listen((doc) {
            setState(() {
              _hasSubscriptions = doc.exists && doc.data() != null && doc.data()!.isNotEmpty;
              _checkingSubscriptions = false;
            });
          });
        } else {
          setState(() {
            _hasSubscriptions = true;
            _checkingSubscriptions = false;
          });
        }
      } else {
        setState(() {
          _isLoggedIn = false;
          _isAdmin = false;
          _hasSubscriptions = false;
          _checkingSubscriptions = false;
        });
      }
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
    if (_checkingSubscriptions) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        debugShowCheckedModeBanner: false,
      );
    }
    return MaterialApp(
      title: 'NEWS NOW',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 2,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          elevation: 6,
          foregroundColor: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Colors.white),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Colors.white,
          contentTextStyle: TextStyle(color: Colors.black),
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
      ),
      home: _isLoggedIn
          ? (_isAdmin
              ? const AdminScreen()
              : (_hasSubscriptions ? const UserScreen() : const SubscriptionPromptScreen()))
          : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
