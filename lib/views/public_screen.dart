//flutter
import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/providers/make_story_providers.dart';
import 'package:apapane/views/common/library_books.dart';
import 'package:apapane/views/common/library_ink_well.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/views/common/reload_screen.dart';
//domain
import 'package:apapane/models/story/story.dart';

class PublicScreen extends ConsumerWidget {
  const PublicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyViewModel = ref.watch(storyViewModelProvider);
    final publicViewModel = ref.watch(publicViewModelProvider);
    final storyDocs = publicViewModel.storyDocs;
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
        body: storyDocs.isEmpty
            ? ReloadScreen(
                onReload: () async => await publicViewModel.onReload())
            : LibraryBooks(
                image: publicImage,
                titleText: publicText,
                height: height,
                width: width,
                refreshController: publicViewModel.refreshController,
                onRefresh: () async => await publicViewModel.onRefresh(),
                onLoading: () async => await publicViewModel.onLoading(),
                child: ListView.builder(
                  itemCount: storyDocs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final storyDoc = storyDocs[index];
                    final Story story = Story.fromJson(storyDoc.data()!);
                    return LibraryInkWell(
                        height: height,
                        width: width,
                        onTap: () async => await publicViewModel.getMyStories(
                            context: context,
                            storyViewModel: storyViewModel,
                            storyDoc: storyDoc),
                        storyImageURL: story.titleImage,
                        titleText: story.titleText);
                  },
                ),
              ));
  }
}
