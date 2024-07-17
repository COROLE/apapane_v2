// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatLogImpl _$$ChatLogImplFromJson(Map<String, dynamic> json) =>
    _$ChatLogImpl(
      chatLog: json['chatLog'] as String,
      chatLogId: json['chatLogId'] as String,
      createdAt: json['createdAt'],
      uid: json['uid'] as String,
      userName: json['userName'] as String,
      updatedAt: json['updatedAt'],
    );

Map<String, dynamic> _$$ChatLogImplToJson(_$ChatLogImpl instance) =>
    <String, dynamic>{
      'chatLog': instance.chatLog,
      'chatLogId': instance.chatLogId,
      'createdAt': instance.createdAt,
      'uid': instance.uid,
      'userName': instance.userName,
      'updatedAt': instance.updatedAt,
    };
