import 'package:apapane/views/abstract/library_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/providers/make_story_providers.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/models/story/story.dart';
import 'package:apapane/views/common/library_ink_well.dart';

class PublicScreen extends LibraryState {
  const PublicScreen({super.key});

  @override
  dynamic getViewModel(WidgetRef ref) => ref.watch(publicViewModelProvider);

  @override
  String getImage() => publicImage;

  @override
  String getTitleText() => publicText;

  @override
  Widget buildLibraryInkWell(BuildContext context, WidgetRef ref, Story story,
      dynamic storyDoc, double height, double width, int index) {
    final storyViewModel = ref.watch(storyViewModelProvider);
    final publicViewModel = ref.watch(publicViewModelProvider);

    return LibraryInkWell(
      height: height,
      width: width,
      onTap: () async => await publicViewModel.getMyStories(
        context: context,
        storyViewModel: storyViewModel,
        storyDoc: storyDoc,
      ),
      storyImageURL: story.titleImage,
      titleText: story.titleText,
    );
  }
}
