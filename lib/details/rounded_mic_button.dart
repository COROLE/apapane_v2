//flutter
import 'package:flutter/material.dart';
//packages
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//constants
import 'package:apapane/constants/voids.dart' as voids;
//models
import 'package:apapane/model/chat_model.dart';

class RoundedMicButton extends ConsumerWidget {
  const RoundedMicButton({Key? key, required this.radius}) : super(key: key);
  final double radius;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatModel chatModel = ref.watch(chatProvider);
    return AvatarGlow(
      animate: chatModel.isListening,
      duration: const Duration(milliseconds: 2000),
      glowColor: Colors.pink,
      child: GestureDetector(
        onTap: () async => await voids.showFluttertoast(msg: 'マイクをながくおしてね！'),
        onLongPressStart: (details) async {
          // 長押しを開始した時にマイクをONにする
          chatModel.startListening(localeId: 'ja_JP'); // 日本語の設定
        },
        onLongPressEnd: (details) {
          // 長押しを終了した時（指を離した時）にマイクをOFFにする
          chatModel.stopListening();
        },
        child: CircleAvatar(
          backgroundColor: Colors.pink.withOpacity(0.5),
          radius: radius,
          child: Icon(
            chatModel.isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
