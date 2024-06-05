//flutter
import 'package:apapane/model/chat_model.dart';
import 'package:flutter/material.dart';
//components
import 'package:apapane/details/rounded_mic_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OriginalFlashBar extends StatelessWidget {
  const OriginalFlashBar({
    Key? key,
    required this.chatModel,
    required this.controller,
    required this.hintText,
    required this.height,
    required this.onPressed,
  }) : super(key: key);
  final ChatModel chatModel;
  final TextEditingController? controller;
  final String hintText;
  final double height;
  final void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      child: Container(
        height: height,
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
            color: Colors.white,
            spreadRadius: 5.w,
            blurRadius: 7.w,
          ),
        ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: RoundedMicButton(
                radius: 25.w,
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(left: 10.w),
                  border: const OutlineInputBorder(),
                  hintText: hintText,
                ),
              ),
            ),
            IconButton(
              onPressed: onPressed,
              icon: const Icon(Icons.send),
              color: Colors.pink,
              iconSize: 35.w,
            ),
          ],
        ),
      ),
    );
  }
}
