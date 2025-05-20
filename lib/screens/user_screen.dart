import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/news_post.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final NewsService _newsService = NewsService();
  final User? _user = FirebaseAuth.instance.currentUser;
  final List<String> _categories = ['General', 'Sports', 'Technology', 'Health', 'Business'];
  List<String> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _newsService.getUserSubscriptions(_user!.uid).listen((subs) {
        setState(() {
          _subscriptions = subs;
        });
      });
    }
  }

  void _toggleSubscription(String category) {
    if (_user == null) return;
    if (_subscriptions.contains(category)) {
      _newsService.unsubscribeFromCategory(_user!.uid, category);
    } else {
      _newsService.subscribeToCategory(_user!.uid, category);
    }
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Subscribe to Categories:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                children: _categories.map((category) {
                  final subscribed = _subscriptions.contains(category);
                  return FilterChip(
                    label: Text(category,
                        style: const TextStyle(color: Colors.white)),
                    selected: subscribed,
                    selectedColor: Colors.grey[800],
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      _toggleSubscription(category);
                    },
                    backgroundColor: Colors.grey[900],
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Your News Feed:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              SizedBox(
                height: 400,
                child: StreamBuilder<List<NewsPost>>(
                  stream: _newsService.getPersonalizedNews(_user!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Error loading news',
                              style: TextStyle(color: Colors.white)));
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.white));
                    }
                    final newsList = snapshot.data!;
                    if (newsList.isEmpty) {
                      return const Center(
                          child: Text('No news posts for your subscriptions',
                              style: TextStyle(color: Colors.white)));
                    }
                    return ListView.builder(
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
        ),
      ),
    );
  }
}
