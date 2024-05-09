// ignore_for_file: file_names

import 'package:apapane/constants/strings.dart';
import 'package:apapane/view/login_signup_screen/login_signup_screen.dart';

import 'package:flutter/material.dart';

class TopScreen extends StatefulWidget {
  const TopScreen({Key? key}) : super(key: key);

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen> {
  String? userName;
  String? password;
  String? mail;
  String? birthday;

  bool showChatScreen = false; // chatScreenを表示するためのフラグ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(seconds: 1), // アニメーションの時間
        child: showChatScreen
            ? LoginSignUpScreen()
            : buildTopScreen(), // TopScreenを表示
      ),
    );
  }

  Widget buildTopScreen() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: FractionalOffset.topLeft,
          end: FractionalOffset.bottomRight,
          colors: [
            const Color.fromARGB(253, 252, 42, 0).withOpacity(0.8),
            const Color.fromARGB(255, 255, 216, 216).withOpacity(0.8),
          ],
          stops: const [
            0.0,
            1.0,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Apapane',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 70),
          ),
          const SizedBox(
            height: 30,
          ),
          Image.asset(
            apapaneImage,
            width: 400,
            height: 400,
          ),
        ],
      ),
    );
  }
}
