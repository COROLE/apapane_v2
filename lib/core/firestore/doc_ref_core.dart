import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';

class DocRefCore {
  static DocRef publicUserDocRef(String uid) =>
      ColRefCore.publicUsersColRef().doc(uid);

  static DocRef chatLogDocRef(String uid, String chatLogId) =>
      ColRefCore.chatLogsColRef(uid).doc(chatLogId);
  static DocRef consumableDocRef(String uid, String purchaseID) =>
      ColRefCore.consumablesColRef(uid).doc(purchaseID);
  static DocRef subscriptionDocRef(String uid, String purchaseID) =>
      ColRefCore.subscriptionsColRef(uid).doc(purchaseID);
  static DocRef favoriteStoryDocRef(String uid, String storyId) =>
      ColRefCore.favoriteStoriesColRef(uid).doc(storyId);

  static DocRef storyDocRef(String uid, String storyId) =>
      ColRefCore.storiesColRef(uid, storyId).doc(storyId);
}
