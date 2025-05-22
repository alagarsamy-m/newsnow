import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPromptScreen extends StatefulWidget {
  const SubscriptionPromptScreen({super.key});

  @override
  State<SubscriptionPromptScreen> createState() => _SubscriptionPromptScreenState();
}

class _SubscriptionPromptScreenState extends State<SubscriptionPromptScreen> {
  final List<String> _categories = ['General', 'Sports', 'Technology', 'Health', 'Business'];
  Set<String> _selectedCategories = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isSaving = false;

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _saveSubscriptions() async {
    if (_user == null) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await _firestore.collection('subscriptions').doc(_user!.uid).set(
        Map.fromIterable(_selectedCategories, key: (e) => e, value: (e) => true),
        SetOptions(merge: true),
      );
      // Pop back to main user screen instead of pushReplacementNamed to preserve navigation stack
      Navigator.of(context).pop(_selectedCategories);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save subscriptions: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscriptions();
  }

  Future<void> _loadCurrentSubscriptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('subscriptions').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      setState(() {
        _selectedCategories = doc.data()!.keys.toSet();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Select Your News Categories', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Please select the categories you want to subscribe to:',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: _categories.map((category) {
                final selected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Text(category, style: const TextStyle(color: Colors.white)),
                  selected: selected,
                  onSelected: (bool selected) {
                    _toggleCategory(category);
                  },
                  selectedColor: Colors.grey[800],
                  backgroundColor: Colors.grey[900],
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSubscriptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: _isSaving ? const CircularProgressIndicator() : const Text('Save Subscriptions'),
            ),
          ],
        ),
      ),
    );
  }
}
