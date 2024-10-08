//flutter
import 'package:apapane/models/firestore_user/firestore_user.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:flutter/material.dart';
//packages
import 'package:cloud_firestore/cloud_firestore.dart';

//TODO:repositoryの追加
class AdminViewModel extends ChangeNotifier {
  final FirestoreRepository _firestoreRepository;
  FirestoreRepository get firestoreRepository => _firestoreRepository;
  AdminViewModel(this._firestoreRepository);

  Future<void> admin({
    required DocumentSnapshot<Map<String, dynamic>> currentUserDoc,
    required FirestoreUser firestoreUser,
  }) async {
    final WriteBatch writeBatch = FirebaseFirestore.instance.batch();
    // //管理者にだけ出来る処理
    // //ユーザーのemailの削除
    // WriteBatch batch = FirebaseFirestore.instance.batch();
    // final result =
    //     await _firestoreRepository.getDocs(ColRefCore.publicUsersColRef());
    // result.when(success: (users) {
    //   for (final user in users) {
    //     user.reference.update({
    //       'silverSubscriptions': FieldValue.delete(),
    //       'consumables': [],
    //       'silverSubscription': {}
    //     });
    //   }
    // }, failure: (e) {
    //  await UIHelper.showFlutterToast('エラーが発生しました');
    // });

    // //postにuserNameの追加
    // final postsQshot = await currentUserDoc.reference.collection('posts').get();
    // for (final post in postsQshot.docs) {
    //   batch.update(post.reference, {
    //     'userName': firestoreUser.userName,
    //     'userImageURL': firestoreUser.userImageURL
    //   });
    // }
    // await batch.commit();

//commentCountの追加
    // WriteBatch writeBatch = FirebaseFirestore.instance.batch();
    // final postsQshot = await currentUserDoc.reference.collection('posts').get();
    // for (final post in postsQshot.docs) {
    //   writeBatch.update(post.reference, {'commentCount': 0});
    // }
    // await writeBatch.commit();

//コレクショングループによる横断的な削除
    // WriteBatch writeBatch = FirebaseFirestore.instance.batch();
    // final commentsQshot =
    //     await FirebaseFirestore.instance.collectionGroup('postComments').get();
    // for (final commentDoc in commentsQshot.docs) {
    //   writeBatch.delete(commentDoc.reference);
    // }
    // await writeBatch.commit();

    // final WriteBatch writeBatch = FirebaseFirestore.instance.batch();
    // //postの削除.limit(100)
    // // final postsQshot = await currentUserDoc.reference
    // //     .collection('posts')
    // //     .orderBy('createdAt', descending: false)
    // //     .limit(100)
    // //     .get();

    // // for (final postDoc in postsQshot.docs) {
    // //   writeBatch.delete(postDoc.reference);
    // // }
    // await writeBatch.commit();
    // final usersQshot =
    //     await FirebaseFirestore.instance.collection('users').get();
    // final WriteBatch writeBatch = FirebaseFirestore.instance.batch();
    // for (final user in usersQshot.docs) {
    //   writeBatch.update(user.reference, {
    //     "muteCount": 0,
    //   });
    // }
    // await writeBatch.commit();

    // for (int i = 0; i < 35; i++) {
    //   final String passiveUid = 'newMuteUser${i.toString()}';
    //   final Timestamp now = Timestamp.now();
    //   final String tokenId = returnUuidV4();
    //   final String activeUid = currentUserDoc.id;
    //   //ユーザーを作成する
    //   final FirestoreUser firestoreUser = FirestoreUser(
    //       createdAt: now,
    //       followerCount: 0,
    //       followingCount: 0,
    //       isAdmin: false,
    //       muteCount: 0,
    //       updatedAt: now,
    //       userName: passiveUid,
    //       userImageURL: '',
    //       uid: passiveUid);
    //   final ref =
    //       FirebaseFirestore.instance.collection('users').doc(passiveUid);
    //   writeBatch.set(ref, firestoreUser.toJson());
    //   //今回はフロントだけの処理を擬似的に実装したいのでDBには保存しない
    //   //ミュートした印を作成する
    //   final MuteUserToken muteUserToken = MuteUserToken(
    //       activeUid: activeUid,
    //       createdAt: now,
    //       passiveUid: passiveUid,
    //       tokenId: tokenId,
    //       tokenType: muteUserTokenTypeString);
    //   //フロントだけの処理
    //   muteUsersModel.newMuteUserTokens.add(muteUserToken);
    //   //Timestampwをずらす
    //   await Future.delayed(const Duration(milliseconds: 300));
    // }

// muteCountの追加
    // final commentsQshot =
    //     await FirebaseFirestore.instance.collectionGroup('postComments').get();
    // for (final commentDoc in commentsQshot.docs) {
    //   writeBatch.update(commentDoc.reference, {'muteCount': 0});
    // }

    //muteCountの追加
    // final postsQshot =
    //     await FirebaseFirestore.instance.collectionGroup('posts').get();
    // for (final postDoc in postsQshot.docs) {
    //   writeBatch.update(postDoc.reference, {'muteCount': 0});
    // }

    // muteCountの追加
    // final repliesQshot = await FirebaseFirestore.instance
    //     .collectionGroup('postCommentReplies')
    //     .get();
    // for (final replyDoc in repliesQshot.docs) {
    //   writeBatch.update(replyDoc.reference, {'muteCount': 0});
    // }

    //followerの作成
    //adminで作成する70人のユーザーを取得する
    // final userQshot =
    //     await FirebaseFirestore.instance.collection('users').limit(70).get();
    // final User currentUser = returnAuthUser()!;
    // for (final userDoc in userQshot.docs) {
    //   final Timestamp now = Timestamp.now();
    //   final String currentUid = currentUser.uid;
    //   final String tokenId = returnUuidV4();
    //   //フォローした証
    //   final FollowingToken followingToken = FollowingToken(
    //       createdAt: now,
    //       passiveUid: currentUid,
    //       tokenId: tokenId,
    //       tokenType: followingTokenTypeString);
    //   writeBatch.set(userDocToTokenDocRef(userDoc: userDoc, tokenId: tokenId),
    //       followingToken.toJson());

    //   //フォローされた証
    //   final Follower follower = Follower(
    //       createdAt: now, followedUid: currentUid, followerUid: userDoc.id);
    //   writeBatch.set(
    //       FirebaseFirestore.instance
    //           .collection('users')
    //           .doc(currentUid)
    //           .collection('followers')
    //           .doc(follower.followerUid),
    //       follower.toJson());
    //   await Future.delayed(const Duration(milliseconds: 100));
    // }

    //firestore_user.dartの更新
    // final usersQshot =
    //     await FirebaseFirestore.instance.collection('users').get();
    // for (final userDoc in usersQshot.docs) {
    //   writeBatch.update(userDoc.reference, {
    //     'searchToken': returnSearchToken(
    //         searchWords: returnSearchWords(searchTerm: userDoc['userName'])),
    //     'postCount': 0,
    //     'userNameLanguageCode': 'en',
    //     'userNameNegativeScore': 0.0,
    //     'userNamePositiveScore': 0.0,
    //     'userNameSentiment': 'POSITIVE'
    //   });
    // }

    //post,comment,replyにuserNameの解析Fieldを追加
    //storyの処理
    // final storiesQshot =
    //     await FirebaseFirestore.instance.collectionGroup('stories').get();
    // for (final storyDoc in storiesQshot.docs) {
    //   writeBatch.update(storyDoc.reference, {
    //     'isPublic': false,
    //   });
    // }
    // //comments全削除
    // final commentsQshot =
    //     await FirebaseFirestore.instance.collectionGroup('postComments').get();

    // for (final commentDoc in commentsQshot.docs) {
    //   writeBatch.delete(commentDoc.reference);
    // }

    // //replies全削除

    // final repliesQshot = await FirebaseFirestore.instance
    //     .collectionGroup('postCommentReplies')
    //     .get();
    // for (final replyDoc in repliesQshot.docs) {
    //   writeBatch.delete(replyDoc.reference);
    // }

    await writeBatch.commit();
    await UIHelper.showFlutterToast('処理が完了しました');
  }
}
