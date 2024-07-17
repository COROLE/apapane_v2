//flutter
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/providers/make_story_providers.dart';
import 'package:apapane/views/common/library_books.dart';
import 'package:apapane/views/common/library_ink_well.dart';
import 'package:apapane/views/common/reload_screen.dart';
import 'package:apapane/view_models/profile_view_model.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
//constants
import 'package:apapane/constants/strings.dart';
//domain
import 'package:apapane/models/story/story.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyViewModel = ref.watch(storyViewModelProvider);
    final publicViewModel = ref.watch(publicViewModelProvider);
    final archiveViewModel = ref.watch(archiveViewModelProvider);
    final mainViewModel = ref.watch(mainViewModelProvider);
    final ProfileViewModel profileModel = ref.watch(profileViewModelProvider);

    final storyDocs = archiveViewModel.storyDocs;
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    if (storyDocs.isEmpty) {
      return Scaffold(
          body: ReloadScreen(
              onReload: () async => await archiveViewModel.onReload()));
    }

    return Scaffold(
      body: LibraryBooks(
        image: archiveImage,
        titleText: archiveText,
        height: height,
        width: width,
        refreshController: archiveViewModel.refreshController,
        onRefresh: () async => await archiveViewModel.onRefresh(),
        onLoading: () async => await archiveViewModel.onLoading(),
        child: ListView.builder(
          itemCount: storyDocs.length,
          itemBuilder: (BuildContext context, int index) {
            final storyDoc = storyDocs[index];
            final Story story = Story.fromJson(storyDoc.data()!);
            return LibraryInkWell(
                height: height,
                width: width,
                onTap: () async => await archiveViewModel.getMyStories(
                    context: context,
                    storyViewModel: storyViewModel,
                    storyDoc: storyDoc),
                storyImageURL: story.titleImage,
                titleText: story.titleText,
                isArchive: true,
                isPublic:
                    archiveViewModel.publicStoryIds.contains(story.storyId),
                // ignore: collection_methods_unrelated_type
                isFavoriteLoading: archiveViewModel.isFavoriteLoading,
                isFavorite:
                    archiveViewModel.favoriteStoryIds.contains(storyDoc.id),
                favoriteButtonPressed: () async {
                  if (archiveViewModel.isFavoriteLoading) return;
                  if (archiveViewModel.favoriteStoryIds.contains(storyDoc.id)) {
                    await archiveViewModel.updateFavorite(
                        context: context,
                        storyViewModel: storyViewModel,
                        index: index,
                        mainViewModel: mainViewModel,
                        isLike: false);
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
                        isLike: true);
                  }
                },
                onChanged: (_) async {
                  if (archiveViewModel.publicStoryIds.contains(story.storyId)) {
                    publicViewModel.removeStoryDocs(storyDoc: storyDoc);
                    archiveViewModel.updatePublicMode(
                        context: context,
                        storyViewModel: storyViewModel,
                        index: index,
                        isOn: false);
                  } else {
                    publicViewModel.addStoryDocs(storyDoc: storyDoc);
                    await archiveViewModel.updatePublicMode(
                        context: context,
                        storyViewModel: storyViewModel,
                        index: index,
                        isOn: true);
                  }
                });
          },
        ),
      ),
    );
  }
}
