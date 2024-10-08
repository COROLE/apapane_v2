//flutter
import 'package:bordered_text/bordered_text.dart';
import 'package:flutter/material.dart';

class RoundedSentence extends StatelessWidget {
  const RoundedSentence({super.key, required this.sentence});
  final String sentence;
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return ListView(scrollDirection: Axis.horizontal, children: [
      Padding(
        padding: EdgeInsets.only(
            top: screenHeight * 0.8,
            left: screenWidth * 0.05,
            right: screenWidth * 0.95,
            bottom: screenHeight * 0.02),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(40),
          ),
          child: BorderedText(
            strokeWidth: 5.0,
            strokeColor: Colors.white,
            child: Text(
              sentence,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
        ),
      ),
    ]);
  }
}
