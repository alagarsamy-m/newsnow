import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/models/news_post.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _newsCollection = 'news_posts';
  final String _subscriptionsCollection = 'subscriptions';

  Future<void> postNews(NewsPost post) async {
    await _firestore.collection(_newsCollection).add(post.toMap());
  }

  Stream<List<NewsPost>> getAllNews() {
    return _firestore
        .collection(_newsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Firestore error in getAllNews: \$error');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => NewsPost.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> subscribeToCategory(String userId, String category) async {
    await _firestore
        .collection(_subscriptionsCollection)
        .doc(userId)
        .set({category: true}, SetOptions(merge: true));
  }

  Future<void> unsubscribeFromCategory(String userId, String category) async {
    await _firestore
        .collection(_subscriptionsCollection)
        .doc(userId)
        .update({category: FieldValue.delete()});
  }

  Stream<List<String>> getUserSubscriptions(String userId) {
    return _firestore
        .collection(_subscriptionsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data()!.keys.toList();
      } else {
        return <String>[];
      }
    });
  }

  Stream<List<NewsPost>> getPersonalizedNews(String userId) {
    return getUserSubscriptions(userId).asyncExpand((categories) {
      if (categories.isEmpty) {
        return Stream.value([]);
      }
      return _firestore
          .collection(_newsCollection)
          .where('category', whereIn: categories)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            print('Firestore error in getPersonalizedNews: \$error');
          })
          .map((snapshot) => snapshot.docs
              .map((doc) => NewsPost.fromMap(doc.data(), doc.id))
              .toList());
    });
  }
}
