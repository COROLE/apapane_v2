//flutter
import 'package:apapane/details/rounded_mic_button.dart';
import 'package:apapane/view/chat_screen/components/custom_chat_theme.dart';
import 'package:apapane/view/chat_screen/components/judge_ui.dart';
import 'package:apapane/view/chat_screen/components/rounded_example_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:apapane/constants/voids.dart' as voids;

//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//constants
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
        : Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 35, 175, 37),
              elevation: 0,
              leading: IconButton(
                onPressed: () => chatModel.backToHomeScreen(context: context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 24,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
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
                  messages: chatModel.messages,
                  onSendPressed: chatModel.handleSendPressed,
                  showUserAvatars: true,
                  showUserNames: true,
                  user: chatModel.user,
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
                          onTap: () => chatModel.toMicUi(context: context),
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
                            onPressed: chatModel.isCommentLoading
                                ? () async => await voids.showFluttertoast(
                                    msg: pleaseWaitMSG)
                                : () => chatModel.exampleAndVoiceSendPressed(
                                    chatModel.exampleText,
                                    context: context),
                            widthRate: 0.35,
                            text: chatModel.isExampleLoading
                                ? '...'
                                : chatModel.exampleText),
                        CreateButton(
                            isValidCreate: chatModel.isValidCreate,
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
                  ])),
              chatModel.isShowCreate
                  ? JudgeUi(
                      screenHeight: screenHeight,
                      screenWidth: screenWidth,
                      chatModel: chatModel,
                      storyModel: storyModel)
                  : const SizedBox.shrink()
            ]),
          );
  }
}
