//flutter
import 'package:flutter/material.dart';

class RoundedTitle extends StatelessWidget {
  const RoundedTitle({
    super.key,
    required this.storyTitle,
  });
  final String storyTitle;
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      height: screenHeight * 0.08,
      width: screenWidth,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft, // グラデーションの始点を変更
          end: Alignment.topRight, // グラデーションの終点を変更
          colors: [
            const Color.fromARGB(255, 26, 20, 50).withOpacity(0.9), // 暗い青紫色
            const Color.fromARGB(255, 202, 89, 255).withOpacity(0.8), // 明るいピンク色
            const Color.fromARGB(255, 64, 224, 208).withOpacity(0.8), // 明るいブルー色
          ],
          stops: const [0.0, 0.5, 1.0], // ストップ位置を調整
        ),
        borderRadius: BorderRadius.circular(2), // 角度を大きく
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: Offset(4, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        storyTitle,
        style: const TextStyle(
          fontSize: 20, // フォントサイズを大きく
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            // テキストに影を追加
            Shadow(
              offset: Offset(1.0, 1.0),
              blurRadius: 3.0,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ],
        ),
      ),
    );
  }
}
