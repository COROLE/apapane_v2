//flutter
import 'package:apapane/providers/make_story_providers.dart';
import 'package:flutter/material.dart';
//packages
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final chatViewModel = ref.watch(chatViewModelProvider);

    return AvatarGlow(
      animate: chatViewModel.isListening,
      duration: const Duration(milliseconds: 800),
      glowColor: Colors.pink,
      child: GestureDetector(
        onTap: isValid
            ? () {
                if (chatViewModel.isListening) {
                  chatViewModel.stopListening();
                } else {
                  chatViewModel.startListening(localeId: 'ja_JP'); // 日本語の設定
                }
              }
            : () => chatViewModel.toMicUi(context: context),
        child: Material(
          elevation: 8,
          shadowColor: Colors.grey.withOpacity(0.5),
          shape: const CircleBorder(),
          child: CircleAvatar(
            backgroundColor: color,
            radius: radius,
            child: Icon(
              chatViewModel.isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
