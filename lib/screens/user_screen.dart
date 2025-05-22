import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/news_post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final NewsService _newsService = NewsService();
  final User? _user = FirebaseAuth.instance.currentUser;
  final List<String> _categories = ['General', 'Sports', 'Technology', 'Health', 'Business'];

  Future<List<String>> _fetchSubscriptions() async {
    if (_user == null) return [];
    final doc = await FirebaseFirestore.instance.collection('subscriptions').doc(_user!.uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!.keys.toList();
    }
    return [];
  }

  Stream<List<String>> _subscriptionStream() {
    if (_user == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('subscriptions').doc(_user!.uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return doc.data()!.keys.toList();
      }
      return <String>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text('User not logged in', style: TextStyle(color: Colors.white)));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchSubscriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading subscriptions: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final subscriptions = snapshot.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your News Feed:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 400,
                  child: StreamBuilder<List<NewsPost>>(
                    stream: _newsService.getPersonalizedNews(_user!.uid),
                    builder: (context, newsSnapshot) {
                      if (newsSnapshot.hasError) {
                        return Center(
                            child: Text('Error loading news: ${newsSnapshot.error}',
                                style: const TextStyle(color: Colors.white)));
                      }
                      if (!newsSnapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator(color: Colors.white));
                      }
                      final newsList = newsSnapshot.data!;
                      if (newsList.isEmpty) {
                        return const Center(
                            child: Text('No news posts for your subscriptions',
                                style: TextStyle(color: Colors.white)));
                      }
                      return ListView.builder(
                        key: ValueKey(newsList.length), // Force rebuild on data change
                        itemCount: newsList.length,
                        itemBuilder: (context, index) {
                          final post = newsList[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[900],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.title,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(post.category,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.white70)),
                                const SizedBox(height: 8),
                                Text(post.content,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.white)),
                                const SizedBox(height: 8),
                                Text('${post.timestamp.toLocal()}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
