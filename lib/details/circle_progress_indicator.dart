//flutter
import 'package:flutter/material.dart';
//constants
import 'package:apapane/constants/strings.dart';

class CircleProgressIndicator extends StatelessWidget {
  const CircleProgressIndicator({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            circleIndicatorImage,
            fit: BoxFit.cover,
            height: screenHeight,
          ),
          SafeArea(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // 画面中央に表示するために追加
                children: [
                  SizedBox(height: screenHeight * 0.33), // 画面中央に表示するために追加
                  Container(
                      decoration: BoxDecoration(boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 255, 252, 252)
                              .withOpacity(0.7),
                          spreadRadius: 5,
                          blurRadius: 7,
                          // changes position of shadow
                        ),
                      ]),
                      child: Text(message,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black))),

                  SizedBox(height: screenHeight * 0.05), // 画面中央に表示するために追加
                  CircularProgressIndicator(
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.pink, // Use a single color for the indicator
                    ),
                    strokeWidth: 5.0,
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
