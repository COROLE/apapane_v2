import 'package:freezed_annotation/freezed_annotation.dart';

part 'firestore_user.freezed.dart';
part 'firestore_user.g.dart';

@freezed
abstract class FirestoreUser with _$FirestoreUser {
  const factory FirestoreUser({
    required int age,
    @Default(0) int coins,
    required dynamic createdAt,
    @Default(0) int favoriteMyStoryCount,
    @Default(0) int followerCount,
    @Default(0) int followingCount,
    @Default(false) bool isAdmin,
    @Default([]) List<Map<String, dynamic>> consumables,
    @Default({}) Map<String, dynamic> silverSubscription,
    required dynamic updatedAt,
    required String userName,
    required String userImageURL,
    required String uid,
  }) = _FirestoreUser;
  factory FirestoreUser.fromJson(Map<String, dynamic> json) =>
      _$FirestoreUserFromJson(json);
}
