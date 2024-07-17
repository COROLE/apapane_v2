import 'package:apapane/ui_core/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:apapane/constants/strings.dart';
import 'package:apapane/views/common/circle_progress_indicator.dart';
import 'package:apapane/views/common/create_button.dart';
import 'package:apapane/views/common/rounded_mic_button.dart';
import 'package:apapane/views/chat_screen/components/custom_chat_theme.dart';
import 'package:apapane/views/chat_screen/components/judge_ui.dart';
import 'package:apapane/views/chat_screen/components/rounded_example_button.dart';
import 'package:apapane/providers/make_story_providers.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatViewModel = ref.watch(chatViewModelProvider);
    final storyViewModel = ref.watch(storyViewModelProvider);
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return chatViewModel.isLoading
        ? const CircleProgressIndicator(
            message: makingMSG, circleIndicatorImage: circleIndicatorImage)
        : Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 35, 175, 37),
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Colors.white, // アイコンを白色に変更
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 11.0, top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        color: Color.fromARGB(255, 245, 206, 10),
                        size: 10,
                      ),
                      SizedBox(width: 3),
                      Text(
                        "apapane",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              title: const Text(
                makeStoryTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            body: Stack(children: [
              Chat(
                  messages: chatViewModel.messages,
                  onSendPressed: (message) =>
                      chatViewModel.handleSendPressed(context, message),
                  showUserAvatars: true,
                  showUserNames: true,
                  user: chatViewModel.user,
                  theme: const CustomChatTheme(),
                  avatarBuilder: (user) => const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color.fromARGB(255, 254, 254, 254),
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
                        GestureDetector(
                          onTap: () => chatViewModel.toMicUi(context: context),
                          child: const Hero(
                              tag: 'micButton',
                              transitionOnUserGestures: true,
                              child: RoundedMicButton(
                                radius: 26.0,
                                isValid: false,
                                color: Color.fromARGB(255, 251, 188, 5),
                              )),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        RoundedExampleButton(
                            onPressed: chatViewModel.isCommentLoading
                                ? () async => await UIHelper.showFlutterToast(
                                    pleaseWaitMSG)
                                : () =>
                                    chatViewModel.exampleAndVoiceSendPressed(
                                        chatViewModel.exampleText,
                                        context: context),
                            widthRate: 0.35,
                            text: chatViewModel.isExampleLoading
                                ? '...'
                                : chatViewModel.exampleText),
                        CreateButton(
                            isValidCreate: chatViewModel.isValidCreate,
                            width: screenWidth * 0.35,
                            height: screenHeight * 0.045,
                            onPressed: chatViewModel.isCommentLoading
                                ? () async => await UIHelper.showFlutterToast(
                                    pleaseWaitMSG)
                                : () => chatViewModel.createButtonPressed(
                                    context: context,
                                    storyViewModel: storyViewModel)),
                        SizedBox(width: screenWidth * 0.03),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Input(
                      isAttachmentUploading: false,
                      onSendPressed: (types.PartialText message) {
                        chatViewModel.handleSendPressed(context, message);
                      },
                      options: const InputOptions(),
                    ),
                  ])),
              chatViewModel.isShowCreate
                  ? JudgeUi(
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      onPressed: chatViewModel.isCommentLoading
                          ? () async => await UIHelper.showFlutterToast(
                                pleaseWaitMSG,
                              )
                          : () => chatViewModel.createButtonPressed(
                                context: context,
                                storyViewModel: storyViewModel,
                              ),
                      chatViewModel: chatViewModel,
                    )
                  : const SizedBox.shrink()
            ]),
          );
  }
}
