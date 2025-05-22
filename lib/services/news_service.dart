import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/models/news_post.dart';
import 'package:rxdart/rxdart.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _newsCollection = 'news_posts';
  final String _subscriptionsCollection = 'subscriptions';

  Future<void> postNews(NewsPost post) async {
    await _firestore.collection(_newsCollection).add(post.toMap());
  }

  Future<void> updateNews(NewsPost post) async {
    if (post.id == null) {
      throw Exception('Post ID is null');
    }
    await _firestore.collection(_newsCollection).doc(post.id).update(post.toMap());
  }

  Future<void> deleteNews(String postId) async {
    await _firestore.collection(_newsCollection).doc(postId).delete();
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
      if (categories == null || categories.isEmpty) {
        // Return all news if no subscriptions
        return getAllNews();
      }
      try {
        // Firestore whereIn supports max 10 items, so split if needed
        if (categories.length <= 10) {
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
                  .toList())
              .handleError((error) {
                print('Firestore error in getPersonalizedNews map: \$error');
              });
        } else {
          // Split categories into chunks of 10 and merge streams
          final chunks = <List<String>>[];
          for (var i = 0; i < categories.length; i += 10) {
            chunks.add(categories.sublist(i, i + 10 > categories.length ? categories.length : i + 10));
          }
          final streams = chunks.map((chunk) => _firestore
              .collection(_newsCollection)
              .where('category', whereIn: chunk)
              .orderBy('timestamp', descending: true)
              .snapshots()
              .handleError((error) {
                print('Firestore error in getPersonalizedNews chunk: \$error');
              })
              .map((snapshot) => snapshot.docs
                  .map((doc) => NewsPost.fromMap(doc.data(), doc.id))
                  .toList())
              .handleError((error) {
                print('Firestore error in getPersonalizedNews chunk map: \$error');
              })
          );
          return Rx.combineLatestList(streams).map((listOfLists) => listOfLists.expand((x) => x).toList());
        }
      } catch (e) {
        print('Exception in getPersonalizedNews: \$e');
        return Stream.value(<NewsPost>[]);
      }
    });
  }

  Stream<List<NewsPost>> getPersonalizedNewsByCategory(String userId, String category) {
    return _firestore.collection(_subscriptionsCollection).doc(userId).snapshots().asyncExpand((doc) {
      if (doc.exists && doc.data() != null && doc.data()!.containsKey(category)) {
        return _firestore
            .collection(_newsCollection)
            .where('category', isEqualTo: category)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .handleError((error) {
              print('Firestore error in getPersonalizedNewsByCategory: \$error');
            })
            .map((snapshot) => snapshot.docs
                .map((doc) => NewsPost.fromMap(doc.data(), doc.id))
                .toList());
      } else {
        return Stream.value(<NewsPost>[]);
      }
    });
  }
}
