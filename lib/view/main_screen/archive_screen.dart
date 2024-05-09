//flutter
import 'package:apapane/details/library_books.dart';
import 'package:apapane/details/library_ink_well.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
//model
import 'package:apapane/model/main/archive_model.dart';
import 'package:apapane/model/story_model.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/reload_screen.dart';
//domain
import 'package:apapane/domain/story/story.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StoryModel storyModel = ref.watch(storyProvider);
    final ArchiveModel archiveModel = ref.watch(archiveProvider);
    final storyDocs = archiveModel.storyDocs;
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: storyDocs.isEmpty
            ? ReloadScreen(onReload: () async => await archiveModel.onReload())
            : LibraryBooks(
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
                        titleText: story.titleText);
                  },
                ),
              ));
  }
}
