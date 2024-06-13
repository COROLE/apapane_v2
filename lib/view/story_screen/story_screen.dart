import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/model/story_model.dart';
import 'package:apapane/model/main_model.dart';
import 'package:apapane/view/story_screen/components/rounded_story_screen.dart';
import 'package:apapane/view/story_screen/components/end_story_screen.dart';
import 'package:apapane/view/story_screen/components/start_story_screen.dart';
import 'package:apapane/details/rounded_title.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({Key? key, required this.isNew}) : super(key: key);
  final bool isNew;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('StoryScreen built, isNew: $isNew');
    final MainModel mainModel = ref.watch(mainProvider);
    final StoryModel storyModel = ref.watch(storyProvider);

    final pagesList = <Widget>[
      StartStoryScreen(
        seconds: 30,
        child: RoundedTitle(
          storyTitle: storyModel.titleText,
        ),
      ),
      ...storyModel.storyPages.map((page) {
        if (!isNew) {
          return FutureBuilder<Uint8List?>(
              future: storyModel.fetchImageData(page["image"]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    return RoundedStoryScreen(
                      storyModel: storyModel,
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
            storyModel: storyModel,
            picture: null,
            sentence: page['story'].toString(),
          );
        }
        String? base64Image = page["image"];
        Uint8List? image =
            base64Image != null ? base64Decode(base64Image) : null;

        return RoundedStoryScreen(
          storyModel: storyModel,
          picture: image,
          sentence: page['story'].toString(),
        );
      }),
      EndStoryScreen(storyModel: storyModel, mainModel: mainModel)
    ];
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 46, 46, 46),
      body: PageView(
        scrollDirection: Axis.vertical,
        onPageChanged: (int pageIndex) {
          storyModel.onPageChanged();
        },
        children: pagesList,
      ),
    );
  }
}
