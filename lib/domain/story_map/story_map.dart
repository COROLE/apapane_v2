import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_map.g.dart';

@JsonSerializable()
class StoryMap {
  String image;
  String story;
  StoryMap({required this.image, required this.story});
  factory StoryMap.fromJson(Map<String, dynamic> json) =>
      _$StoryMapFromJson(json);
  Map<String, dynamic> toJson() => _$StoryMapToJson(this);
}
