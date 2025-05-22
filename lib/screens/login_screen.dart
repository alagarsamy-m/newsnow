import 'package:flutter/material.dart';
import 'package:news_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/utils/auth_state_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  String _errorMessage = '';

  void _toggleFormType() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
  }

  Future<void> _initializeUserSubscription(String userId) async {
    final docRef = FirebaseFirestore.instance.collection('subscriptions').doc(userId);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({}, SetOptions(merge: true));
    }
  }

  Future<void> _submit() async {
    try {
      if (_isLogin) {
        User? user = await _authService.signInWithEmailAndPassword(
            _emailController.text, _passwordController.text);
        if (user != null) {
          // Check if user is admin
          final isAdmin = user.email?.toLowerCase() == 'admin@example.com';
          if (mounted) {
            if (isAdmin) {
              Navigator.of(context).pushReplacementNamed('/admin');
            } else {
              Navigator.of(context).pushReplacementNamed('/main_user');
            }
          }
        }
      } else {
        User? user = await _authService.registerWithEmailAndPassword(
            _emailController.text, _passwordController.text);
          if (user != null) {
          // Set flag to ignore next auth change event in main.dart before registration call
          AuthStateManager().ignoreNextAuthChange = true;
          // Initialize subscription document for new user
          await _initializeUserSubscription(user.uid);
          // Do not sign out user after registration to keep them logged in
          // await _authService.signOut();
          // Show registration success dialog and prompt user to login
          if (mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Registration Successful'),
                content: const Text('Account successfully registered. Please login with your registered account.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            setState(() {
              _isLogin = true;
              // Do not clear input fields on registration success
              // _emailController.clear();
              // _passwordController.clear();
              _errorMessage = '';
            });
            // Do not navigate automatically; user must login manually
            // Navigator.of(context).pushReplacementNamed('/subscription_prompt');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Account not found. Please register your account.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Incorrect password. Please try again.';
        } else if (e.code == 'invalid-credential' || e.code == 'invalid-email') {
          _errorMessage = 'Invalid credentials.\n Please check your email and password.';
        } else {
          _errorMessage = e.message ?? 'Authentication error occurred.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // Replace the Flutter icon with the splash screen icon (Icons.feed)
            Icon(
              Icons.feed,
              size: 32,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'NEWS NOW',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: _toggleFormType,
                child: Text(
                  _isLogin
                      ? 'Don\'t have an account? Register'
                      : 'Have an account? Login',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
