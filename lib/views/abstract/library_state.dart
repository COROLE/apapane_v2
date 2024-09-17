import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/views/common/library_books.dart';
import 'package:apapane/views/common/reload_screen.dart';
import 'package:apapane/models/story/story.dart';

abstract class LibraryState extends ConsumerWidget {
  const LibraryState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = getViewModel(ref);
    final storyDocs = viewModel.storyDocs;
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;

    if (storyDocs.isEmpty) {
      return Scaffold(
        body: ReloadScreen(onReload: () async => await viewModel.onReload()),
      );
    }

    return Scaffold(
      body: LibraryBooks(
        image: getImage(),
        titleText: getTitleText(),
        height: height,
        width: width,
        refreshController: viewModel.refreshController,
        onRefresh: () async => await viewModel.onRefresh(),
        onLoading: () async => await viewModel.onLoading(),
        child: ListView.builder(
          itemCount: storyDocs.length,
          itemBuilder: (BuildContext context, int index) {
            final storyDoc = storyDocs[index];
            final Story story = Story.fromJson(storyDoc.data()!);
            return buildLibraryInkWell(
                context, ref, story, storyDoc, height, width, index);
          },
        ),
      ),
    );
  }

  dynamic getViewModel(WidgetRef ref);
  String getImage();
  String getTitleText();
  Widget buildLibraryInkWell(BuildContext context, WidgetRef ref, Story story,
      dynamic storyDoc, double height, double width, int index);
}
