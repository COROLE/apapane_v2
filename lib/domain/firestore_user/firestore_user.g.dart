// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FirestoreUserImpl _$$FirestoreUserImplFromJson(Map<String, dynamic> json) =>
    _$FirestoreUserImpl(
      age: (json['age'] as num).toInt(),
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'],
      favoriteMyStoryCount:
          (json['favoriteMyStoryCount'] as num?)?.toInt() ?? 0,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
      isAdmin: json['isAdmin'] as bool? ?? false,
      consumables: (json['consumables'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      silverSubscription:
          json['silverSubscription'] as Map<String, dynamic>? ?? const {},
      updatedAt: json['updatedAt'],
      userName: json['userName'] as String,
      userImageURL: json['userImageURL'] as String,
      uid: json['uid'] as String,
    );

Map<String, dynamic> _$$FirestoreUserImplToJson(_$FirestoreUserImpl instance) =>
    <String, dynamic>{
      'age': instance.age,
      'coins': instance.coins,
      'createdAt': instance.createdAt,
      'favoriteMyStoryCount': instance.favoriteMyStoryCount,
      'followerCount': instance.followerCount,
      'followingCount': instance.followingCount,
      'isAdmin': instance.isAdmin,
      'consumables': instance.consumables,
      'silverSubscription': instance.silverSubscription,
      'updatedAt': instance.updatedAt,
      'userName': instance.userName,
      'userImageURL': instance.userImageURL,
      'uid': instance.uid,
    };
