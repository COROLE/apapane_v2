//flutter
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

void toStoryScreenReplacement({required BuildContext context}) =>
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const StoryScreen()));
void toStoryScreen({required BuildContext context}) => Navigator.push(
    context, MaterialPageRoute(builder: (context) => const StoryScreen()));

void toHomeScreen({required BuildContext context}) => Navigator.pushReplacement(
    context, MaterialPageRoute(builder: (context) => const HomeScreen()));

void toChatScreen(
        {required BuildContext context, required String apapaneTitle}) =>
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ChatScreen(apapaneTitle: apapaneTitle)));

void toFirstScreen({required BuildContext context}) =>
    Navigator.of(context).popUntil((route) => route.isFirst);
