// ignore_for_file: file_names

import 'package:freezed_annotation/freezed_annotation.dart';
part 'chatLog.freezed.dart';
part 'chatLog.g.dart';

@freezed
class ChatLog with _$ChatLog {
  const factory ChatLog({
    required String chatLog,
    required dynamic chatLogId,
    required dynamic createdAt,
    required String uid,
    required String userName,
    required dynamic updatedAt,
  }) = _ChatLog;

  factory ChatLog.fromJson(Map<String, dynamic> json) =>
      _$ChatLogFromJson(json);
}
