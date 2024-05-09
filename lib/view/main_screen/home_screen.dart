//flutter
import 'package:flutter/material.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/rounded_start_button.dart';
import 'package:bordered_text/bordered_text.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//models
import 'package:apapane/model/chat_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatModel chatModel = ref.watch(chatProvider);

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (BuildContext context, Widget? widget) =>
            SingleChildScrollView(
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
                top: screenHeight * 0.35.w,
                left: screenWidth * 0.15.w,
                child: InkWell(
                  onTap: () => chatModel.chatInit(
                      context: context, apapaneTitle: startUpperTitle),
                  child: const RoundedStartButton(
                    startTitle: startAdventureText,
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.09.h,
                right: screenWidth * 0.1.w,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    // アイコンと枠線の間のスペース
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green,
                        width: 1.w,
                      ),
                      shape: BoxShape.circle, // 枠線の形状
                      color: const Color.fromARGB(255, 255, 255, 255), // 枠線の色
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.notifications,
                      size: 25.w,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.5.h,
                right: screenWidth * 0,
                child: Image.asset(
                  apapaneImage,
                  width: screenWidth * 0.45.w,
                  height: screenWidth * 0.45.w,
                ), // ここに写真を配置します
              ),
              Positioned(
                  top: screenHeight * 0.08.h,
                  left: screenWidth * 0.1.w,
                  child: BorderedText(
                    strokeWidth: 8.0.w,
                    strokeColor: const Color.fromARGB(255, 255, 128, 128),
                    child: Text(startUpperTitle,
                        style: TextStyle(
                            fontSize: 30.w,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
