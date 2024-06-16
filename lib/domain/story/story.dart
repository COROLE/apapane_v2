import 'package:freezed_annotation/freezed_annotation.dart';

part 'story.freezed.dart';
part 'story.g.dart';

@freezed
class Story with _$Story {
  const factory Story({
    required dynamic createdAt,
    required dynamic chatLogRef,
    required bool isPublic,
    required List<Map<String, dynamic>> stories,
    required String storyId,
    required String titleImage,
    required String titleText,
    required String uid,
    required String userImageURL,
    required String userName,
    required dynamic updatedAt,
  }) = _Story;

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);
}
