import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QueryCore {
  static MapQuery publicUsersOrderByFollowerCount() =>
      ColRefCore.publicUsersColRef().orderBy("followerCount", descending: true);

  static MapQuery subscriptionGetByEndDate(String uid) =>
      ColRefCore.subscriptionsColRef(uid)
          .orderBy('endDate', descending: true)
          .limit(1);

  static MapQuery archiveStoriesCollectionQuery(User currentUser) =>
      FirebaseFirestore.instance
          .collectionGroup("stories")
          .where('uid', isEqualTo: currentUser.uid)
          .orderBy("createdAt", descending: true)
          .limit(15);

  static MapQuery publicStoriesCollectionQuery() => FirebaseFirestore.instance
      .collectionGroup("stories")
      .where('isPublic', isEqualTo: true)
      .orderBy("createdAt", descending: true)
      .limit(15);

  static MapQuery newStoriesCollectionQuery(
      User? currentUser, List<Doc> docs, bool isArchive) {
    if (isArchive) {
      return archiveStoriesCollectionQuery(currentUser!)
          .endBeforeDocument(docs.first);
    } else {
      return publicStoriesCollectionQuery().endBeforeDocument(docs.first);
    }
  }

  static MapQuery oldStoriesCollectionQuery(
      User? currentUser, List<Doc> docs, bool isArchive) {
    if (isArchive) {
      return archiveStoriesCollectionQuery(currentUser!)
          .startAfterDocument(docs.last);
    } else {
      return publicStoriesCollectionQuery().startAfterDocument(docs.last);
    }
  }

  static MapQuery whereInUsersQuery(List<String> uids) =>
      ColRefCore.publicUsersColRef().where('uid', whereIn: uids);

  // static MapQuery userPostsQuery(String uid) =>
  //     ColRefCore.postsColRef(uid).limit(10);
}
