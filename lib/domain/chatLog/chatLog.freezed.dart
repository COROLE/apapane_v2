// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chatLog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatLog _$ChatLogFromJson(Map<String, dynamic> json) {
  return _ChatLog.fromJson(json);
}

/// @nodoc
mixin _$ChatLog {
  String get chatLog => throw _privateConstructorUsedError;
  dynamic get chatLogId => throw _privateConstructorUsedError;
  dynamic get createdAt => throw _privateConstructorUsedError;
  String get uid => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  dynamic get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatLogCopyWith<ChatLog> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatLogCopyWith<$Res> {
  factory $ChatLogCopyWith(ChatLog value, $Res Function(ChatLog) then) =
      _$ChatLogCopyWithImpl<$Res, ChatLog>;
  @useResult
  $Res call(
      {String chatLog,
      dynamic chatLogId,
      dynamic createdAt,
      String uid,
      String userName,
      dynamic updatedAt});
}

/// @nodoc
class _$ChatLogCopyWithImpl<$Res, $Val extends ChatLog>
    implements $ChatLogCopyWith<$Res> {
  _$ChatLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatLog = null,
    Object? chatLogId = freezed,
    Object? createdAt = freezed,
    Object? uid = null,
    Object? userName = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      chatLog: null == chatLog
          ? _value.chatLog
          : chatLog // ignore: cast_nullable_to_non_nullable
              as String,
      chatLogId: freezed == chatLogId
          ? _value.chatLogId
          : chatLogId // ignore: cast_nullable_to_non_nullable
              as dynamic,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatLogImplCopyWith<$Res> implements $ChatLogCopyWith<$Res> {
  factory _$$ChatLogImplCopyWith(
          _$ChatLogImpl value, $Res Function(_$ChatLogImpl) then) =
      __$$ChatLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String chatLog,
      dynamic chatLogId,
      dynamic createdAt,
      String uid,
      String userName,
      dynamic updatedAt});
}

/// @nodoc
class __$$ChatLogImplCopyWithImpl<$Res>
    extends _$ChatLogCopyWithImpl<$Res, _$ChatLogImpl>
    implements _$$ChatLogImplCopyWith<$Res> {
  __$$ChatLogImplCopyWithImpl(
      _$ChatLogImpl _value, $Res Function(_$ChatLogImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatLog = null,
    Object? chatLogId = freezed,
    Object? createdAt = freezed,
    Object? uid = null,
    Object? userName = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ChatLogImpl(
      chatLog: null == chatLog
          ? _value.chatLog
          : chatLog // ignore: cast_nullable_to_non_nullable
              as String,
      chatLogId: freezed == chatLogId
          ? _value.chatLogId
          : chatLogId // ignore: cast_nullable_to_non_nullable
              as dynamic,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatLogImpl implements _ChatLog {
  const _$ChatLogImpl(
      {required this.chatLog,
      required this.chatLogId,
      required this.createdAt,
      required this.uid,
      required this.userName,
      required this.updatedAt});

  factory _$ChatLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatLogImplFromJson(json);

  @override
  final String chatLog;
  @override
  final dynamic chatLogId;
  @override
  final dynamic createdAt;
  @override
  final String uid;
  @override
  final String userName;
  @override
  final dynamic updatedAt;

  @override
  String toString() {
    return 'ChatLog(chatLog: $chatLog, chatLogId: $chatLogId, createdAt: $createdAt, uid: $uid, userName: $userName, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatLogImpl &&
            (identical(other.chatLog, chatLog) || other.chatLog == chatLog) &&
            const DeepCollectionEquality().equals(other.chatLogId, chatLogId) &&
            const DeepCollectionEquality().equals(other.createdAt, createdAt) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            const DeepCollectionEquality().equals(other.updatedAt, updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      chatLog,
      const DeepCollectionEquality().hash(chatLogId),
      const DeepCollectionEquality().hash(createdAt),
      uid,
      userName,
      const DeepCollectionEquality().hash(updatedAt));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatLogImplCopyWith<_$ChatLogImpl> get copyWith =>
      __$$ChatLogImplCopyWithImpl<_$ChatLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatLogImplToJson(
      this,
    );
  }
}

abstract class _ChatLog implements ChatLog {
  const factory _ChatLog(
      {required final String chatLog,
      required final dynamic chatLogId,
      required final dynamic createdAt,
      required final String uid,
      required final String userName,
      required final dynamic updatedAt}) = _$ChatLogImpl;

  factory _ChatLog.fromJson(Map<String, dynamic> json) = _$ChatLogImpl.fromJson;

  @override
  String get chatLog;
  @override
  dynamic get chatLogId;
  @override
  dynamic get createdAt;
  @override
  String get uid;
  @override
  String get userName;
  @override
  dynamic get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ChatLogImplCopyWith<_$ChatLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
