//flutter
import 'package:apapane/enums/confirm_action.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter/cupertino.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
//models
import 'package:apapane/view_models/main_view_model.dart';
import 'package:go_router/go_router.dart';

class EndStoryScreen extends StatelessWidget {
  const EndStoryScreen(
      {super.key, required this.storyViewModel, required this.mainViewModel});
  final StoryViewModel storyViewModel;
  final MainViewModel mainViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(endImage),
          fit: BoxFit.cover, // This is to cover the container with the image
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              try {
                switch (storyViewModel.toStoryPageType) {
                  case ToStoryPageType.memoryStory:
                    Navigator.pop(context);
                    break;
                  case ToStoryPageType.newStory:
                    showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext innerContext) =>
                          CupertinoActionSheet(
                        title: const Text(selectTitle),
                        actions: [
                          CupertinoActionSheetAction(
                            // This parameter indicates the action would perform
                            // a destructive action such as delete or exit and turns
                            // the action's text color to red.
                            isDestructiveAction: true,
                            onPressed: () async {
                              storyViewModel.confirmAction = ConfirmAction.save;
                              innerContext.pop();
                              context.pop();

                              await storyViewModel.endButtonPressed(
                                  context: innerContext,
                                  mainViewModel:
                                      mainViewModel); // Set the onPressed callback to the handleButtonPress method
                            },
                            child: const Text(
                              saveText,
                              style: TextStyle(color: Colors.pink),
                            ),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () async {
                              storyViewModel.confirmAction =
                                  ConfirmAction.cancel;
                              innerContext.pop();
                              context.pop();
                              await storyViewModel.endButtonPressed(
                                  context: innerContext,
                                  mainViewModel:
                                      mainViewModel); // Set the onPressed callback to the handleButtonPress method
                            },
                            child: const Text(noText),
                          ),
                        ],
                      ),
                    );
                    break;
                  case ToStoryPageType.initialValue:
                    Navigator.pop(context);
                    break;
                }
              } catch (e) {
                debugPrint('error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color.fromARGB(196, 255, 2, 86),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: const Text(
              endButtonText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white, // テキストの色を白に
              ),
            ),
          ),
        ),
      ),
    );
  }
}
