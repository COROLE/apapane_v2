import 'dart:convert';
import 'dart:typed_data';
import 'package:apapane/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/views/story_screen/components/rounded_story_screen.dart';
import 'package:apapane/views/story_screen/components/end_story_screen.dart';
import 'package:apapane/views/story_screen/components/start_story_screen.dart';
import 'package:apapane/views/common/rounded_title.dart';
import 'package:apapane/providers/make_story_providers.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key, required this.isNew});
  final bool isNew;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('StoryScreen built, isNew: $isNew');
    final mainViewModel = ref.watch(mainViewModelProvider);
    final storyViewModel = ref.watch(storyViewModelProvider);

    final pagesList = <Widget>[
      StartStoryScreen(
        seconds: 30,
        child: RoundedTitle(
          storyTitle: storyViewModel.titleText,
        ),
      ),
      ...storyViewModel.storyPages.map((page) {
        if (!isNew) {
          return FutureBuilder<Uint8List?>(
              future: storyViewModel.fetchImageData(page["image"]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return RoundedStoryScreen(
                      storyViewModel: storyViewModel,
                      picture: snapshot.data,
                      sentence: page['story'].toString(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('画像の読み込みに失敗しました: ${snapshot.error}'));
                  }
                }
                return const Center(child: CircularProgressIndicator());
              });
        }
        if (page["image"] == null) {
          return RoundedStoryScreen(
            storyViewModel: storyViewModel,
            picture: null,
            sentence: page['story'].toString(),
          );
        }
        String? base64Image = page["image"];
        Uint8List? image =
            base64Image != null ? base64Decode(base64Image) : null;

        return RoundedStoryScreen(
          storyViewModel: storyViewModel,
          picture: image,
          sentence: page['story'].toString(),
        );
      }),
      EndStoryScreen(
          storyViewModel: storyViewModel, mainViewModel: mainViewModel)
    ];
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 46, 46, 46),
      body: PageView(
        scrollDirection: Axis.vertical,
        onPageChanged: (int pageIndex) {
          storyViewModel.onPageChanged();
        },
        children: pagesList,
      ),
    );
  }
}
