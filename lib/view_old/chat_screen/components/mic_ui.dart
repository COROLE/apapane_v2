import 'package:apapane/details/original_flash_bar.dart';
import 'package:apapane/details/rounded_mic_button.dart';
import 'package:apapane/model_riverpod_old/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MicUi extends ConsumerWidget {
  const MicUi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatModel chatModel = ref.watch(chatProvider);
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('しゃべってね',
            style: TextStyle(
                color: Color.fromARGB(255, 77, 77, 77),
                fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Hero(
                tag: 'micButton',
                transitionOnUserGestures: true,
                child: RoundedMicButton(
                  radius: 70,
                  isValid: true,
                  color: Colors.pink,
                )),
            SizedBox(height: screenHeight * 0.1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: OriginalFlashBar(
                  controller: chatModel.textController,
                  hintText: 'こえがはいるよ',
                  height: screenHeight * 0.1,
                  onPressed: () => chatModel.exampleAndVoiceSendPressed(
                      chatModel.textController.text,
                      isVoice: true,
                      context: context)),
            )
          ],
        ),
      ),
    );
  }
}
