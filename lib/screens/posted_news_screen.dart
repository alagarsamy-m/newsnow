import 'package:flutter/material.dart';
import 'package:news_app/services/news_service.dart';
import 'package:news_app/models/news_post.dart';

class PostedNewsScreen extends StatefulWidget {
  const PostedNewsScreen({super.key});

  @override
  State<PostedNewsScreen> createState() => _PostedNewsScreenState();
}

class _PostedNewsScreenState extends State<PostedNewsScreen> {
  final NewsService _newsService = NewsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Posted News', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<NewsPost>>(
        stream: _newsService.getAllNews(),
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
                child: Text('No news posts yet',
                    style: TextStyle(color: Colors.white)));
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(post.title,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            _showEditDialog(post);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmation(post.id);
                          },
                        ),
                      ],
                    ),
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
    );
  }

  void _showEditDialog(NewsPost post) {
    final _titleController = TextEditingController(text: post.title);
    final _contentController = TextEditingController(text: post.content);
    String _selectedCategory = post.category;
    final List<String> _categories = ['General', 'Sports', 'Technology', 'Health', 'Business'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Edit News Post', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category, style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _selectedCategory = value;
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[900],
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[900],
                    labelText: 'Title',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[900],
                    labelText: 'Content',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                final updatedPost = NewsPost(
                  id: post.id,
                  title: _titleController.text,
                  content: _contentController.text,
                  category: _selectedCategory,
                  timestamp: DateTime.now(),
                );
                try {
                  await _newsService.updateNews(updatedPost);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('News post updated successfully')),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update news post: \$e')),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String? postId) {
    if (postId == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Delete News Post', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this news post?', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _newsService.deleteNews(postId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('News post deleted successfully')),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete news post: \$e')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
