//flutter
import 'package:flutter/material.dart';
//packages
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoundedExampleButton extends StatelessWidget {
  const RoundedExampleButton(
      {Key? key,
      required this.onPressed,
      required this.widthRate,
      required this.text})
      : super(key: key);

  final void Function()? onPressed;
  final double widthRate;
  final String text;
  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    return ScreenUtilInit(
      child: SizedBox(
          width: maxWidth * widthRate,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                shadowColor: Colors.grey.withOpacity(0.5), // シャドウの色と透明度
                elevation: 8,
                backgroundColor: const Color.fromARGB(255, 66, 133, 244)),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0.w, horizontal: 4.0.w),
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.w,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )),
    );
  }
}
