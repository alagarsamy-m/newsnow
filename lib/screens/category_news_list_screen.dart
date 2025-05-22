import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/news_post.dart';

class CategoryNewsListScreen extends StatefulWidget {
  final String category;

  const CategoryNewsListScreen({super.key, required this.category});

  @override
  State<CategoryNewsListScreen> createState() => _CategoryNewsListScreenState();
}

class _CategoryNewsListScreenState extends State<CategoryNewsListScreen> {
  final NewsService _newsService = NewsService();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.category),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('User not logged in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<List<NewsPost>>(
        stream: _newsService.getPersonalizedNewsByCategory(_user!.uid, widget.category),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading news: \${snapshot.error}', style: const TextStyle(color: Colors.white)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final newsList = snapshot.data!;
          if (newsList.isEmpty) {
            return const Center(
              child: Text('No news posts for this category', style: TextStyle(color: Colors.white)),
            );
          }
          return ListView.builder(
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final post = newsList[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(post.category,
                        style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(post.content,
                        style: const TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('\${post.timestamp.toLocal()}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
