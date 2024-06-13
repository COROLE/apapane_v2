import 'package:apapane/view/chat_screen/components/mic_ui.dart';
import 'package:apapane/view/main_screen/home_screen.dart';
import 'package:flutter/material.dart';
//pages
import 'package:apapane/main.dart';
import 'package:apapane/view/login_signup_screen/login_signup_screen.dart';
import 'package:apapane/view/chat_screen/chat_screen.dart';
import 'package:apapane/view/story_screen/story_screen.dart';

void toMyApp({required BuildContext context}) => Navigator.pushReplacement(
    context, MaterialPageRoute(builder: (context) => MyApp()));

void toLoginSignupScreen({required BuildContext context}) =>
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => const LoginSignUpScreen()));
void toStoryScreenReplacement(
        {required BuildContext context, required bool isNew}) =>
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => StoryScreen(isNew: isNew),
      ),
    );

void toStoryScreen({required BuildContext context, required bool isNew}) =>
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => StoryScreen(
                  isNew: isNew,
                )));

void toHomeScreen({required BuildContext context}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    }
  });
}

void toChatScreen({required BuildContext context}) => Navigator.push(
    context, MaterialPageRoute(builder: (context) => const ChatScreen()));

void toFirstScreen({required BuildContext context}) =>
    Navigator.of(context).popUntil((route) => route.isFirst);

void toMicUi({required BuildContext context}) => Navigator.push(
    context, MaterialPageRoute(builder: (context) => const MicUi()));
