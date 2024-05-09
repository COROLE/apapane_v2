//flutter
import 'package:apapane/details/rounded_button.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//constants
import 'package:apapane/constants/voids.dart' as voids;
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/original_flash_bar.dart';
import 'package:apapane/details/circle_progress_indicator.dart';
import 'package:apapane/details/create_button.dart';
import 'package:apapane/view/chat_screen/components/chat_ui.dart';
//models
import 'package:apapane/model/story_model.dart';
import 'package:apapane/model/chat_model.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.apapaneTitle});
  final String apapaneTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatModel chatModel = ref.watch(chatProvider);
    final StoryModel storyModel = ref.watch(storyProvider);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return chatModel.isLoading
        ? const CircleProgressIndicator(message: makingMSG)
        // ignore: deprecated_member_use
        : Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              elevation: 0,
              leading: IconButton(
                onPressed: () => chatModel.backToHomeScreen(context: context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 24,
                  color: Colors.black,
                ),
              ),
              title: const Text(
                makeStoryTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 11.0, top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_stories,
                        color: Colors.pink,
                        size: 10,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        apapaneTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChatUi(chatModel: chatModel, screenHeight: screenHeight),
                chatModel.isComplete
                    ? Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(width: screenWidth * 0.03),
                              CreateButton(
                                  width: screenWidth * 0.45,
                                  height: screenHeight * 0.05,
                                  onPressed: chatModel.isCommentLoading
                                      ? () async => await voids
                                          .showFluttertoast(msg: pleaseWaitMSG)
                                      : () async =>
                                          await chatModel.createButtonPressed(
                                              context: context,
                                              storyModel: storyModel)),
                              SizedBox(width: screenWidth * 0.05),
                              RoundedButton(
                                  onPressed: () => chatModel
                                      .toggleIsCompleteAndTalk(context),
                                  widthRate: 0.4,
                                  color: const Color.fromARGB(255, 41, 41, 41),
                                  text: "まだはなす"),
                            ],
                          ),
                          SizedBox(
                            height: screenHeight * 0.15,
                          )
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CreateButton(
                              width: screenWidth * 0.3,
                              height: screenHeight * 0.03,
                              onPressed: chatModel.isCommentLoading
                                  ? () async => await voids.showFluttertoast(
                                      msg: pleaseWaitMSG)
                                  : () async =>
                                      await chatModel.createButtonPressed(
                                          context: context,
                                          storyModel: storyModel)),
                          SizedBox(
                            height: screenHeight * 0.01,
                          ),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                          //   children: [
                          //     RoundedExampleButton(
                          //         onPressed: chatModel.isCommentLoading
                          //             ? () async => await voids
                          //                 .showFluttertoast(msg: pleaseWaitMSG)
                          //             : () async => await chatModel.sendMessage(
                          //                 chatModel.exampleText, true),
                          //         widthRate: 0.45,
                          //         text: chatModel.isExampleLoading
                          //             ? '...'
                          //             : chatModel.exampleText),
                          //     RoundedExampleButton(
                          //         onPressed: chatModel.isCommentLoading
                          //             ? () async => await voids
                          //                 .showFluttertoast(msg: pleaseWaitMSG)
                          //             : () async => await chatModel.sendMessage(
                          //                 chatModel.exampleText2, true),
                          //         widthRate: 0.45,
                          //         text: chatModel.isExampleLoading
                          //             ? '...'
                          //             : chatModel.exampleText2),
                          //   ],
                          // ),
                          OriginalFlashBar(
                            chatModel: chatModel,
                            controller: chatModel.textController,
                            hintText: chatHintText,
                            height: screenHeight * 0.1,
                            onPressed: chatModel.isCommentLoading
                                ? () async => await voids.showFluttertoast(
                                    msg: pleaseWaitMSG)
                                : () async => await chatModel
                                    .sendMessageFromButton(context: context),
                          ),
                          SizedBox(
                            height: screenHeight * 0.04,
                          )
                        ],
                      ),
              ],
            ),
          );
  }
}
