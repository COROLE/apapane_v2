// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoryImpl _$$StoryImplFromJson(Map<String, dynamic> json) => _$StoryImpl(
      createdAt: json['createdAt'],
      chatLogRef: json['chatLogRef'],
      isPublic: json['isPublic'] as bool? ?? false,
      stories: (json['stories'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      storyId: json['storyId'] as String,
      titleImage: json['titleImage'] as String,
      titleText: json['titleText'] as String,
      uid: json['uid'] as String,
      userImageURL: json['userImageURL'] as String,
      userName: json['userName'] as String,
      updatedAt: json['updatedAt'],
    );

Map<String, dynamic> _$$StoryImplToJson(_$StoryImpl instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt,
      'chatLogRef': instance.chatLogRef,
      'isPublic': instance.isPublic,
      'stories': instance.stories,
      'storyId': instance.storyId,
      'titleImage': instance.titleImage,
      'titleText': instance.titleText,
      'uid': instance.uid,
      'userImageURL': instance.userImageURL,
      'userName': instance.userName,
      'updatedAt': instance.updatedAt,
    };
