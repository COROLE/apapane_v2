//flutter
import 'package:apapane/details/library_books.dart';
import 'package:apapane/details/library_ink_well.dart';
import 'package:apapane/details/reload_screen.dart';
import 'package:apapane/model_riverpod_old/main/profile_model.dart';
import 'package:apapane/model_riverpod_old/main/public_model.dart';
import 'package:apapane/model_riverpod_old/main_model.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
//model
import 'package:apapane/model_riverpod_old/main/archive_model.dart';
import 'package:apapane/model_riverpod_old/story_model.dart';
//constants
import 'package:apapane/constants/strings.dart';
//domain
import 'package:apapane/domain/story/story.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StoryModel storyModel = ref.watch(storyProvider);
    final PublicModel publicModel = ref.watch(publicProvider);
    final ArchiveModel archiveModel = ref.watch(archiveProvider);
    final MainModel mainModel = ref.watch(mainProvider);
    final ProfileModel profileModel = ref.watch(profileProvider);

    final storyDocs = archiveModel.storyDocs;
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    if (storyDocs.isEmpty) {
      return Scaffold(
          body: ReloadScreen(
              onReload: () async => await archiveModel.onReload()));
    }

    return Scaffold(
      body: LibraryBooks(
        image: archiveImage,
        titleText: archiveText,
        height: height,
        width: width,
        refreshController: archiveModel.refreshController,
        onRefresh: () async => await archiveModel.onRefresh(),
        onLoading: () async => await archiveModel.onLoading(),
        child: ListView.builder(
          itemCount: storyDocs.length,
          itemBuilder: (BuildContext context, int index) {
            final storyDoc = storyDocs[index];
            final Story story = Story.fromJson(storyDoc.data()!);
            return LibraryInkWell(
                height: height,
                width: width,
                onTap: () async => await archiveModel.getMyStories(
                    context: context,
                    storyModel: storyModel,
                    storyDoc: storyDoc),
                storyImageURL: story.titleImage,
                titleText: story.titleText,
                isArchive: true,
                isPublic: archiveModel.publicStoryIds.contains(story.storyId),
                // ignore: collection_methods_unrelated_type
                isFavoriteLoading: archiveModel.isFavoriteLoading,
                isFavorite: archiveModel.favoriteStoryIds.contains(storyDoc.id),
                favoriteButtonPressed: () async {
                  if (archiveModel.isFavoriteLoading) return;
                  if (archiveModel.favoriteStoryIds.contains(storyDoc.id)) {
                    await archiveModel.unlike(
                        context: context,
                        storyModel: storyModel,
                        mainModel: mainModel,
                        index: index);
                    profileModel.removeFavoriteStoryDocs(storyDoc: storyDoc);
                  } else {
                    if (archiveModel.favoriteStoryIds.length <
                        archiveModel.maxFavoriteCount) {
                      profileModel.addFavoriteStoryDocs(storyDoc: storyDoc);
                    }
                    await archiveModel.like(
                        context: context,
                        storyModel: storyModel,
                        mainModel: mainModel,
                        index: index);
                  }
                },
                onChanged: (_) async {
                  if (archiveModel.publicStoryIds.contains(story.storyId)) {
                    publicModel.removeStoryDocs(storyDoc: storyDoc);
                    await archiveModel.offPublicMode(
                        context: context,
                        storyModel: storyModel,
                        mainModel: mainModel,
                        index: index);
                  } else {
                    publicModel.addStoryDocs(storyDoc: storyDoc);
                    await archiveModel.onPublicMode(
                        context: context,
                        storyModel: storyModel,
                        mainModel: mainModel,
                        index: index);
                  }
                });
          },
        ),
      ),
    );
  }
}
