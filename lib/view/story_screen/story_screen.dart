//flutter
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//models
import 'package:apapane/model/story_model.dart';
import 'package:apapane/model/main_model.dart';
//components
import 'package:apapane/view/story_screen/components/rounded_story_screen.dart';
import 'package:apapane/view/story_screen/components/end_story_screen.dart';
import 'package:apapane/view/story_screen/components/start_story_screen.dart';
import 'package:apapane/details/rounded_title.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MainModel mainModel = ref.watch(mainProvider);
    final StoryModel storyModel = ref.watch(storyProvider);
    // ここでstoryModelからstoryPagesを取得し、それぞれのページをリストに追加します。
    final pagesList = <Widget>[
      StartStoryScreen(
        seconds: 30,
        child: RoundedTitle(
          storyTitle: storyModel.titleText,
        ),
      ),
      // storyModelから取得した各ストーリーページをここに追加します。
      ...storyModel.storyPages.map((page) {
        return RoundedStoryScreen(
          storyModel: storyModel,
          picture: page["image"].toString(),
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
