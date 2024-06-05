import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

@immutable
class CustomChatTheme extends DefaultChatTheme {
  const CustomChatTheme()
      : super(
          // 入力フィールドの背景色
          inputTextStyle: const TextStyle(fontWeight: FontWeight.bold),
          inputTextCursorColor: Colors.white,

          inputTextDecoration: const InputDecoration(
            hintText: 'こたえよう!!', // ヒントテキスト
            border: InputBorder.none, // アンダーバーを消す
          ),
          primaryColor: const Color.fromARGB(255, 29, 190, 35),
          receivedMessageBodyTextStyle: const TextStyle(
            color: Color.fromARGB(255, 19, 19, 19), // 任意の色
            fontSize: 16, // 任意のフォントサイズ
            fontWeight: FontWeight.normal, // フォントを太字に設定
            height: 1.5,
          ),
          sentMessageBodyTextStyle: const TextStyle(
            color: Colors.white, // 任意の色
            fontSize: 16, // 任意のフォントサイズ
            fontWeight: FontWeight.bold, // フォントを太字に設定
            height: 1.5,
          ),
        );
}
