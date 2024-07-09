//flutter
import 'package:flutter/material.dart';
//packages
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//models
import 'package:apapane/model_riverpod_old/chat_model.dart';

class RoundedMicButton extends ConsumerWidget {
  const RoundedMicButton(
      {super.key,
      required this.radius,
      required this.isValid,
      required this.color});
  final double radius;
  final bool isValid;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatModel chatModel = ref.watch(chatProvider);

    return AvatarGlow(
      animate: chatModel.isListening,
      duration: const Duration(milliseconds: 800),
      glowColor: Colors.pink,
      child: GestureDetector(
        onTap: isValid
            ? () {
                if (chatModel.isListening) {
                  chatModel.stopListening();
                } else {
                  chatModel.startListening(localeId: 'ja_JP'); // 日本語の設定
                }
              }
            : () => chatModel.toMicUi(context: context),
        child: Material(
          elevation: 8,
          shadowColor: Colors.grey.withOpacity(0.5),
          shape: const CircleBorder(),
          child: CircleAvatar(
            backgroundColor: color,
            radius: radius,
            child: Icon(
              chatModel.isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
