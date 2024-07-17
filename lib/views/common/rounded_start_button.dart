import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoundedStartButton extends StatelessWidget {
  const RoundedStartButton({super.key, required this.startTitle});
  final String startTitle;
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (BuildContext context, Widget? widget) => Stack(
        children: <Widget>[
          Container(
            width: screenWidth * 0.7,
            height: screenHeight * 0.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade300.withOpacity(0.9),
                  Colors.red.shade600.withOpacity(0.8),
                  Colors.purple.shade300.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.w),
                bottomRight: Radius.circular(60.w),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 12.w),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      startTitle,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.w,
                      ),
                    ),
                  ),
                  SizedBox(height: 22.w),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.double_arrow_rounded,
                      color: Colors.white,
                      size: 25.w,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
