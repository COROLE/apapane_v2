//flutter
import 'package:flutter/material.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/rounded_start_button.dart';
import 'package:bordered_text/bordered_text.dart';
import 'package:flutter/services.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//models
import 'package:apapane/model/chat_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画面の向きを縦向きに固定
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final ChatModel chatModel = ref.watch(chatProvider);

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Stack(
          children: [
            Image.asset(
              homeImage,
              height: screenHeight,
              width: screenWidth,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: screenHeight * 0.35,
              left: screenWidth * 0.15,
              child: InkWell(
                onTap: () => chatModel.init(context),
                child: const RoundedStartButton(
                  startTitle: startAdventureText,
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.09,
              right: screenWidth * 0.1,
              child: InkWell(
                onTap: () {},
                child: Container(
                  // アイコンと枠線の間のスペース
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green,
                      width: 1,
                    ),
                    shape: BoxShape.circle, // 枠線の形状
                    color: const Color.fromARGB(255, 255, 255, 255), // 枠線の色
                  ),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(
                    Icons.notifications,
                    size: 25,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.56,
              right: screenWidth * 0,
              child: Image.asset(
                apapaneImage,
                width: screenWidth * 0.45,
                height: screenWidth * 0.45,
              ), // ここに写真を配置します
            ),
            Positioned(
                top: screenHeight * 0.08,
                left: screenWidth * 0.1,
                child: BorderedText(
                  strokeWidth: 8.0,
                  strokeColor: const Color.fromARGB(255, 255, 128, 128),
                  child: const Text(startUpperTitle,
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                )),
          ],
        ),
      ),
    );
  }
}
