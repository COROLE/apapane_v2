// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'story.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Story _$StoryFromJson(Map<String, dynamic> json) {
  return _Story.fromJson(json);
}

/// @nodoc
mixin _$Story {
  dynamic get createdAt => throw _privateConstructorUsedError;
  dynamic get chatLogRef => throw _privateConstructorUsedError;
  bool get isPublic => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get stories => throw _privateConstructorUsedError;
  String get storyId => throw _privateConstructorUsedError;
  String get titleImage => throw _privateConstructorUsedError;
  String get titleText => throw _privateConstructorUsedError;
  String get uid => throw _privateConstructorUsedError;
  String get userImageURL => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  dynamic get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StoryCopyWith<Story> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoryCopyWith<$Res> {
  factory $StoryCopyWith(Story value, $Res Function(Story) then) =
      _$StoryCopyWithImpl<$Res, Story>;
  @useResult
  $Res call(
      {dynamic createdAt,
      dynamic chatLogRef,
      bool isPublic,
      List<Map<String, dynamic>> stories,
      String storyId,
      String titleImage,
      String titleText,
      String uid,
      String userImageURL,
      String userName,
      dynamic updatedAt});
}

/// @nodoc
class _$StoryCopyWithImpl<$Res, $Val extends Story>
    implements $StoryCopyWith<$Res> {
  _$StoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? createdAt = freezed,
    Object? chatLogRef = freezed,
    Object? isPublic = null,
    Object? stories = null,
    Object? storyId = null,
    Object? titleImage = null,
    Object? titleText = null,
    Object? uid = null,
    Object? userImageURL = null,
    Object? userName = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
      chatLogRef: freezed == chatLogRef
          ? _value.chatLogRef
          : chatLogRef // ignore: cast_nullable_to_non_nullable
              as dynamic,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      stories: null == stories
          ? _value.stories
          : stories // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      storyId: null == storyId
          ? _value.storyId
          : storyId // ignore: cast_nullable_to_non_nullable
              as String,
      titleImage: null == titleImage
          ? _value.titleImage
          : titleImage // ignore: cast_nullable_to_non_nullable
              as String,
      titleText: null == titleText
          ? _value.titleText
          : titleText // ignore: cast_nullable_to_non_nullable
              as String,
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      userImageURL: null == userImageURL
          ? _value.userImageURL
          : userImageURL // ignore: cast_nullable_to_non_nullable
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
abstract class _$$StoryImplCopyWith<$Res> implements $StoryCopyWith<$Res> {
  factory _$$StoryImplCopyWith(
          _$StoryImpl value, $Res Function(_$StoryImpl) then) =
      __$$StoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {dynamic createdAt,
      dynamic chatLogRef,
      bool isPublic,
      List<Map<String, dynamic>> stories,
      String storyId,
      String titleImage,
      String titleText,
      String uid,
      String userImageURL,
      String userName,
      dynamic updatedAt});
}

/// @nodoc
class __$$StoryImplCopyWithImpl<$Res>
    extends _$StoryCopyWithImpl<$Res, _$StoryImpl>
    implements _$$StoryImplCopyWith<$Res> {
  __$$StoryImplCopyWithImpl(
      _$StoryImpl _value, $Res Function(_$StoryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? createdAt = freezed,
    Object? chatLogRef = freezed,
    Object? isPublic = null,
    Object? stories = null,
    Object? storyId = null,
    Object? titleImage = null,
    Object? titleText = null,
    Object? uid = null,
    Object? userImageURL = null,
    Object? userName = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$StoryImpl(
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
      chatLogRef: freezed == chatLogRef
          ? _value.chatLogRef
          : chatLogRef // ignore: cast_nullable_to_non_nullable
              as dynamic,
      isPublic: null == isPublic
          ? _value.isPublic
          : isPublic // ignore: cast_nullable_to_non_nullable
              as bool,
      stories: null == stories
          ? _value._stories
          : stories // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      storyId: null == storyId
          ? _value.storyId
          : storyId // ignore: cast_nullable_to_non_nullable
              as String,
      titleImage: null == titleImage
          ? _value.titleImage
          : titleImage // ignore: cast_nullable_to_non_nullable
              as String,
      titleText: null == titleText
          ? _value.titleText
          : titleText // ignore: cast_nullable_to_non_nullable
              as String,
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      userImageURL: null == userImageURL
          ? _value.userImageURL
          : userImageURL // ignore: cast_nullable_to_non_nullable
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
class _$StoryImpl implements _Story {
  const _$StoryImpl(
      {required this.createdAt,
      required this.chatLogRef,
      this.isPublic = false,
      required final List<Map<String, dynamic>> stories,
      required this.storyId,
      required this.titleImage,
      required this.titleText,
      required this.uid,
      required this.userImageURL,
      required this.userName,
      required this.updatedAt})
      : _stories = stories;

  factory _$StoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoryImplFromJson(json);

  @override
  final dynamic createdAt;
  @override
  final dynamic chatLogRef;
  @override
  @JsonKey()
  final bool isPublic;
  final List<Map<String, dynamic>> _stories;
  @override
  List<Map<String, dynamic>> get stories {
    if (_stories is EqualUnmodifiableListView) return _stories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stories);
  }

  @override
  final String storyId;
  @override
  final String titleImage;
  @override
  final String titleText;
  @override
  final String uid;
  @override
  final String userImageURL;
  @override
  final String userName;
  @override
  final dynamic updatedAt;

  @override
  String toString() {
    return 'Story(createdAt: $createdAt, chatLogRef: $chatLogRef, isPublic: $isPublic, stories: $stories, storyId: $storyId, titleImage: $titleImage, titleText: $titleText, uid: $uid, userImageURL: $userImageURL, userName: $userName, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoryImpl &&
            const DeepCollectionEquality().equals(other.createdAt, createdAt) &&
            const DeepCollectionEquality()
                .equals(other.chatLogRef, chatLogRef) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            const DeepCollectionEquality().equals(other._stories, _stories) &&
            (identical(other.storyId, storyId) || other.storyId == storyId) &&
            (identical(other.titleImage, titleImage) ||
                other.titleImage == titleImage) &&
            (identical(other.titleText, titleText) ||
                other.titleText == titleText) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.userImageURL, userImageURL) ||
                other.userImageURL == userImageURL) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            const DeepCollectionEquality().equals(other.updatedAt, updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(createdAt),
      const DeepCollectionEquality().hash(chatLogRef),
      isPublic,
      const DeepCollectionEquality().hash(_stories),
      storyId,
      titleImage,
      titleText,
      uid,
      userImageURL,
      userName,
      const DeepCollectionEquality().hash(updatedAt));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StoryImplCopyWith<_$StoryImpl> get copyWith =>
      __$$StoryImplCopyWithImpl<_$StoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoryImplToJson(
      this,
    );
  }
}

abstract class _Story implements Story {
  const factory _Story(
      {required final dynamic createdAt,
      required final dynamic chatLogRef,
      final bool isPublic,
      required final List<Map<String, dynamic>> stories,
      required final String storyId,
      required final String titleImage,
      required final String titleText,
      required final String uid,
      required final String userImageURL,
      required final String userName,
      required final dynamic updatedAt}) = _$StoryImpl;

  factory _Story.fromJson(Map<String, dynamic> json) = _$StoryImpl.fromJson;

  @override
  dynamic get createdAt;
  @override
  dynamic get chatLogRef;
  @override
  bool get isPublic;
  @override
  List<Map<String, dynamic>> get stories;
  @override
  String get storyId;
  @override
  String get titleImage;
  @override
  String get titleText;
  @override
  String get uid;
  @override
  String get userImageURL;
  @override
  String get userName;
  @override
  dynamic get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$StoryImplCopyWith<_$StoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
