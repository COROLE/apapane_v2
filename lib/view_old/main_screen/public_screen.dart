//flutter
import 'package:apapane/details/library_books.dart';
import 'package:apapane/details/library_ink_well.dart';
import 'package:apapane/model_riverpod_old/main/public_model.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
//model
import 'package:apapane/model_riverpod_old/story_model.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/reload_screen.dart';
//domain
import 'package:apapane/domain/story/story.dart';

class PublicScreen extends ConsumerWidget {
  const PublicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StoryModel storyModel = ref.watch(storyProvider);
    final PublicModel publicModel = ref.watch(publicProvider);
    final storyDocs = publicModel.storyDocs;
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: storyDocs.isEmpty
            ? ReloadScreen(onReload: () async => await publicModel.onReload())
            : LibraryBooks(
                image: publicImage,
                titleText: publicText,
                height: height,
                width: width,
                refreshController: publicModel.refreshController,
                onRefresh: () async => await publicModel.onRefresh(),
                onLoading: () async => await publicModel.onLoading(),
                child: ListView.builder(
                  itemCount: storyDocs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final storyDoc = storyDocs[index];
                    final Story story = Story.fromJson(storyDoc.data()!);
                    return LibraryInkWell(
                        height: height,
                        width: width,
                        onTap: () async => await publicModel.getMyStories(
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
