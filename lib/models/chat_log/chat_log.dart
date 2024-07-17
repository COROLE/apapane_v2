import 'package:freezed_annotation/freezed_annotation.dart';
part 'chat_log.freezed.dart';
part 'chat_log.g.dart';

@freezed
class ChatLog with _$ChatLog {
  const factory ChatLog({
    required String chatLog,
    required String chatLogId,
    required dynamic createdAt,
    required String uid,
    required String userName,
    required dynamic updatedAt,
  }) = _ChatLog;

  factory ChatLog.fromJson(Map<String, dynamic> json) =>
      _$ChatLogFromJson(json);
}
