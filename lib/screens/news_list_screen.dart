import 'package:flutter/material.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/news_post.dart';

class NewsListScreen extends StatefulWidget {
  final String category;
  final String userId;

  const NewsListScreen({Key? key, required this.category, required this.userId}) : super(key: key);

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final NewsService _newsService = NewsService();

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final category = args?['category'] ?? widget.category;
    final userId = args?['userId'] ?? widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text('$category News'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<List<NewsPost>>(
        stream: _newsService.getPersonalizedNewsByCategory(
            userId,
            category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final newsList = snapshot.data ?? [];
          if (newsList.isEmpty) {
            return const Center(child: Text('No news available', style: TextStyle(color: Colors.white)));
          }
          return ListView.builder(
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(news.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(news.content, style: const TextStyle(color: Colors.white70)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
