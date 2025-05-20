import 'package:cloud_firestore/cloud_firestore.dart';

class NewsPost {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime timestamp;

  NewsPost({
    this.id = '',
    required this.title,
    required this.content,
    required this.category,
    required this.timestamp,
  });

  factory NewsPost.fromMap(Map<String, dynamic> data, String documentId) {
    return NewsPost(
      id: documentId,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'timestamp': timestamp,
    };
  }
}
