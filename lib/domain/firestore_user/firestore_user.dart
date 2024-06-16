import 'package:freezed_annotation/freezed_annotation.dart';

part 'firestore_user.freezed.dart';
part 'firestore_user.g.dart';

@freezed
abstract class FirestoreUser with _$FirestoreUser {
  const factory FirestoreUser({
    required int age,
    required dynamic createdAt,
    required int favoriteMyStoryCount,
    required int followerCount,
    required int followingCount,
    required bool isAdmin,
    required dynamic updatedAt,
    required String userName,
    required String userImageURL,
    required String uid,
  }) = _FirestoreUser;
  factory FirestoreUser.fromJson(Map<String, dynamic> json) =>
      _$FirestoreUserFromJson(json);
}
