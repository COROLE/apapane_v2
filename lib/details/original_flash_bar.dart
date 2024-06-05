//flutter
import 'package:flutter/material.dart';
//components
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OriginalFlashBar extends StatelessWidget {
  const OriginalFlashBar({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.height,
    required this.onPressed,
  }) : super(key: key);

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
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(left: 10.w),
                    border: const OutlineInputBorder(),
                    hintText: hintText,
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.pink),
                    )),
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
