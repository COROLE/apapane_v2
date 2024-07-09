import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QueryCore {
  static MapQuery publicUsersOrderByFollowerCount() =>
      ColRefCore.publicUsersColRef().orderBy("followerCount", descending: true);

  static MapQuery subscriptionGetByEndDate(String uid) =>
      ColRefCore.subscriptionsColRef(uid)
          .orderBy('endDate', descending: true)
          .limit(1);

  static MapQuery postsCollectionQuery() => FirebaseFirestore.instance
      .collectionGroup("posts")
      .orderBy("createdAt", descending: true)
      .limit(10);

  static MapQuery whereInUsersQuery(List<String> uids) =>
      ColRefCore.publicUsersColRef().where('uid', whereIn: uids);

  // static MapQuery userPostsQuery(String uid) =>
  //     ColRefCore.postsColRef(uid).limit(10);
}
