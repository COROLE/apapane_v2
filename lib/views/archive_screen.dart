import 'package:apapane/views/abstract/library_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/providers/make_story_providers.dart';
import 'package:apapane/view_models/profile_view_model.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/models/story/story.dart';
import 'package:apapane/views/common/library_ink_well.dart';

class ArchiveScreen extends LibraryState {
  const ArchiveScreen({super.key});

  @override
  dynamic getViewModel(WidgetRef ref) => ref.watch(archiveViewModelProvider);

  @override
  String getImage() => archiveImage;

  @override
  String getTitleText() => archiveText;

  @override
  Widget buildLibraryInkWell(BuildContext context, WidgetRef ref, Story story,
      dynamic storyDoc, double height, double width, int index) {
    final storyViewModel = ref.watch(storyViewModelProvider);
    final publicViewModel = ref.watch(publicViewModelProvider);
    final archiveViewModel = ref.watch(archiveViewModelProvider);
    final mainViewModel = ref.watch(mainViewModelProvider);
    final ProfileViewModel profileModel = ref.watch(profileViewModelProvider);

    return LibraryInkWell(
      height: height,
      width: width,
      onTap: () async => await archiveViewModel.getMyStories(
        context: context,
        storyViewModel: storyViewModel,
        storyDoc: storyDoc,
      ),
      storyImageURL: story.titleImage,
      titleText: story.titleText,
      isArchive: true,
      isPublic: archiveViewModel.publicStoryIds.contains(story.storyId),
      isFavoriteLoading: archiveViewModel.isFavoriteLoading,
      isFavorite: archiveViewModel.favoriteStoryIds.contains(storyDoc.id),
      favoriteButtonPressed: () async {
        if (archiveViewModel.isFavoriteLoading) return;
        if (archiveViewModel.favoriteStoryIds.contains(storyDoc.id)) {
          await archiveViewModel.updateFavorite(
            context: context,
            storyViewModel: storyViewModel,
            index: index,
            mainViewModel: mainViewModel,
            isLike: false,
          );
          profileModel.removeFavoriteStoryDocs(storyDoc: storyDoc);
        } else {
          if (archiveViewModel.favoriteStoryIds.length <
              archiveViewModel.maxFavoriteCount) {
            profileModel.addFavoriteStoryDocs(storyDoc: storyDoc);
          }
          await archiveViewModel.updateFavorite(
            context: context,
            storyViewModel: storyViewModel,
            index: index,
            mainViewModel: mainViewModel,
            isLike: true,
          );
        }
      },
      onChanged: (_) async {
        if (archiveViewModel.publicStoryIds.contains(story.storyId)) {
          publicViewModel.removeStoryDocs(storyDoc: storyDoc);
          archiveViewModel.updatePublicMode(
            context: context,
            storyViewModel: storyViewModel,
            index: index,
            isOn: false,
          );
        } else {
          publicViewModel.addStoryDocs(storyDoc: storyDoc);
          await archiveViewModel.updatePublicMode(
            context: context,
            storyViewModel: storyViewModel,
            index: index,
            isOn: true,
          );
        }
      },
    );
  }
}
