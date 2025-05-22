import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainUserScreen extends StatefulWidget {
  const MainUserScreen({super.key});

  @override
  State<MainUserScreen> createState() => _MainUserScreenState();
}

class _MainUserScreenState extends State<MainUserScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Set<String> _subscriptions = {};

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    if (_user == null) return;
    final doc = await _firestore.collection('subscriptions').doc(_user!.uid).get();
    if (doc.exists && doc.data() != null) {
      setState(() {
        _subscriptions = doc.data()!.keys.toSet();
      });
    }
  }

  void _navigateToCategory(String category) {
    if (!_subscriptions.contains(category)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not Subscribed'),
          content: const Text("You've not subscribed to this category."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed('/news_list', arguments: {
      'category': category,
      'userId': _user?.uid ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your News Categories'),
        backgroundColor: Colors.black,
        actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              },
            ),
        ],
      ),
      body: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _categoryBox('General'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _categoryBox('Sports'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _categoryBox('Technology'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _categoryBox('Health'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _categoryBox('Business'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _categoryBox('Breaking News'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed('/subscription_prompt');
                if (result != null && result is Set<String>) {
                  setState(() {
                    _subscriptions = result;
                  });
                } else {
                  _loadSubscriptions();
                }
              },
              child: const Text('Edit Subscriptions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryBox(String category) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _subscriptions.contains(category) ? const Color.fromARGB(255, 76, 205, 91) : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color.fromARGB(60, 0, 0, 0)),
        ),
        alignment: Alignment.center,
        constraints: const BoxConstraints.expand(),
        child: Text(
          category,
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
