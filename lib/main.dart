import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:news_app/firebase_options.dart';
import 'package:news_app/screens/login_screen.dart';
import 'package:news_app/screens/admin_screen.dart';
import 'package:news_app/screens/user_screen.dart';
import 'package:news_app/screens/subscription_prompt_screen.dart';
import 'package:news_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/utils/auth_state_manager.dart';
import 'package:news_app/screens/posted_news_screen.dart';
import 'package:news_app/screens/main_user_screen.dart';
import 'package:news_app/screens/news_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String ADMIN_EMAIL = 'admin@example.com'; // Set your admin email here
const String ADMIN_UID = 'GdTIsCLGulQJFYAB1AO7vu9gglp2'; // Admin UID fallback for testing

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
  bool _hasSubscriptions = false;
  bool _checkingSubscriptions = false;
  final AuthStateManager _authStateManager = AuthStateManager();

  Future<bool> _checkIfAdmin(String uid, String? email) async {
    try {
      debugPrint('Checking admin status for UID: $uid');
      final doc = await _firestore.collection('admins').doc(uid).get();
      final isAdmin = doc.exists;
      debugPrint('Admin status for UID $uid: $isAdmin');
      if (isAdmin) {
        return true;
      }
      // Fallback: check if email matches admin email
      if (email != null && email.toLowerCase() == ADMIN_EMAIL.toLowerCase()) {
        debugPrint('Admin email fallback matched for $email');
        // Add admin document to Firestore for future checks
        await _firestore.collection('admins').doc(uid).set({'email': email});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // For debugging: force admin login for specific email
  bool _forceAdminLogin(String email) {
    return email.toLowerCase() == ADMIN_EMAIL.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    // On app start, check current user immediately for persistence
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _handleUserLogin(currentUser);
    }
    _authService.authStateChanges.listen((user) async {
      if (_authStateManager.ignoreNextAuthChange) {
        debugPrint('Ignoring auth state change due to flag');
        _authStateManager.ignoreNextAuthChange = false;
        return;
      }
      if (user != null) {
        _handleUserLogin(user);
      } else {
        setState(() {
          _isLoggedIn = false;
          _isAdmin = false;
          _hasSubscriptions = false;
          _checkingSubscriptions = false;
        });
      }
    });
  }

  Future<void> _handleUserLogin(user) async {
    debugPrint('User logged in: ${user.email} with UID: ${user.uid}');
    setState(() {
      _isLoggedIn = true;
      _checkingSubscriptions = true;
    });
    bool adminStatus = await _checkIfAdmin(user.uid, user.email);
    // Fallback check for known admin UID
    if (!adminStatus && user.uid == ADMIN_UID) {
      adminStatus = true;
    }
    debugPrint('Admin status for user ${user.email}: $adminStatus');
    setState(() {
      _isAdmin = adminStatus;
      _checkingSubscriptions = true; // Keep loading while checking subscriptions
    });
    if (!adminStatus) {
      try {
        final doc = await _firestore.collection('subscriptions').doc(user.uid).get();
        setState(() {
          _hasSubscriptions = doc.exists && doc.data() != null && doc.data()!.isNotEmpty;
          _checkingSubscriptions = false;
        });
      } catch (e) {
        debugPrint('Error fetching subscription document: $e');
        setState(() {
          _hasSubscriptions = false;
          _checkingSubscriptions = false;
        });
      }
      _firestore.collection('subscriptions').doc(user.uid).snapshots().listen((doc) {
        setState(() {
          _hasSubscriptions = doc.exists && doc.data() != null && doc.data()!.isNotEmpty;
        });
      });
    } else {
      setState(() {
        _hasSubscriptions = true;
        _checkingSubscriptions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building app with _isAdmin=$_isAdmin, _isLoggedIn=$_isLoggedIn, _hasSubscriptions=$_hasSubscriptions');
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
              : (_hasSubscriptions ? const MainUserScreen() : const SubscriptionPromptScreen()))
          : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/subscription_prompt': (context) => const SubscriptionPromptScreen(),
        '/user': (context) => const UserScreen(),
        '/main_user': (context) => const MainUserScreen(),
        '/posted_news': (context) => const PostedNewsScreen(),
        '/admin': (context) => const AdminScreen(),
        '/news_list': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
          final category = args['category'] ?? '';
          final userId = args['userId'] ?? '';
          return NewsListScreen(category: category, userId: userId);
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
