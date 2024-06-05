//flutter
import 'package:apapane/details/rounded_button.dart';
import 'package:apapane/details/rounded_mic_button.dart';
import 'package:apapane/view/chat_screen/components/custom_chat_theme.dart';
import 'package:apapane/view/chat_screen/components/rounded_example_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//constants
import 'package:apapane/constants/voids.dart' as voids;
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/circle_progress_indicator.dart';
import 'package:apapane/details/create_button.dart';
//models
import 'package:apapane/model/story_model.dart';
import 'package:apapane/model/chat_model.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

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
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 11.0, top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        color: Colors.pink,
                        size: 10,
                      ),
                      SizedBox(width: 3),
                      Text(
                        "apapane",
                        style: TextStyle(
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
            body: Stack(children: [
              Chat(
                  messages: chatModel.messages,
                  onSendPressed: chatModel.handleSendPressed,
                  showUserAvatars: true,
                  showUserNames: true,
                  user: chatModel.user,
                  theme: const CustomChatTheme(),
                  avatarBuilder: (user) => const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color.fromARGB(255, 254, 236, 236),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(apapaneImage),
                          radius: 25,
                          backgroundColor: Colors.white,
                        ),
                      ),
                  customBottomWidget:
                      Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(width: screenWidth * 0.01),
                        const RoundedMicButton(radius: 26),
                        SizedBox(width: screenWidth * 0.01),
                        RoundedExampleButton(
                            onPressed: chatModel.isCommentLoading
                                ? () async => await voids.showFluttertoast(
                                    msg: pleaseWaitMSG)
                                : () => chatModel
                                    .exampleSendPressed(chatModel.exampleText),
                            widthRate: 0.35,
                            text: chatModel.isExampleLoading
                                ? '...'
                                : chatModel.exampleText),
                        CreateButton(
                            width: screenWidth * 0.35,
                            height: screenHeight * 0.045,
                            onPressed: chatModel.isCommentLoading
                                ? () async => await voids.showFluttertoast(
                                    msg: pleaseWaitMSG)
                                : () async =>
                                    await chatModel.createButtonPressed(
                                        context: context,
                                        storyModel: storyModel)),
                        SizedBox(width: screenWidth * 0.03),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Input(
                      isAttachmentUploading: false,
                      onSendPressed: (types.PartialText message) =>
                          chatModel.handleSendPressed(message),
                      options: const InputOptions(),
                    ),
                    // 必要に応じてオプションを設定
                  ])),
              chatModel.isShowCreate
                  ? Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.black.withOpacity(0.5),
                      child: Column(
                        children: [
                          Icon(
                            Icons.brightness_medium,
                            color: Colors.white,
                            size: screenWidth * 0.5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CreateButton(
                                  width: screenWidth * 0.3,
                                  height: screenHeight * 0.03,
                                  onPressed: chatModel.isCommentLoading
                                      ? () async => await voids
                                          .showFluttertoast(msg: pleaseWaitMSG)
                                      : () async =>
                                          await chatModel.createButtonPressed(
                                              context: context,
                                              storyModel: storyModel)),
                              RoundedButton(
                                  onPressed: () => chatModel.cancel(),
                                  widthRate: 0.4,
                                  color: const Color.fromARGB(255, 41, 41, 41),
                                  text: "まだはなす"),
                            ],
                          )
                        ],
                      ))
                  : const SizedBox.shrink()
            ]),
          );
  }
}
