import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ColRefCore {
  static ColRef publicUsersColRef() =>
      FirebaseFirestore.instance.collection('users');

  static ColRef chatLogsColRef(String uid) =>
      DocRefCore.publicUserDocRef(uid).collection("chatLogs");
  static ColRef consumablesColRef(String uid) =>
      DocRefCore.publicUserDocRef(uid).collection("consumables");
  static ColRef subscriptionsColRef(String uid) =>
      DocRefCore.publicUserDocRef(uid).collection("subscriptions");
  static ColRef favoriteStoriesColRef(String uid) =>
      DocRefCore.publicUserDocRef(uid).collection("favoriteStories");

  static ColRef storiesColRef(String uid, String chatLogId) =>
      DocRefCore.chatLogDocRef(uid, chatLogId).collection("stories");
}
