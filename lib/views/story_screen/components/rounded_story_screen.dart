import 'dart:typed_data';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';
import 'package:apapane/views/common/rounded_sentence.dart';

class RoundedStoryScreen extends StatelessWidget {
  const RoundedStoryScreen(
      {super.key,
      required this.storyViewModel,
      required this.picture,
      required this.sentence});
  final StoryViewModel storyViewModel;
  final Uint8List? picture;
  final String sentence;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    Widget imageWidget;

    try {
      if (picture == null) {
        debugPrint('Picture is null');
        imageWidget = Container(
          width: screenWidth,
          height: screenHeight,
          color: Colors.grey,
          child: const Center(
            child: Text('画像を表示できません'),
          ),
        );
      } else {
        final decodedImage = picture;
        imageWidget = Container(
          width: screenWidth,
          height: screenHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
                image: MemoryImage(decodedImage!), fit: BoxFit.cover),
          ),
        );
      }
    } catch (e) {
      // デコードに失敗した場合のフォールバックとして、エラーメッセージを表示
      debugPrint('Failed to decode image: $e');
      imageWidget = Container(
        width: screenWidth,
        height: screenHeight,
        color: Colors.grey,
        child: const Center(
          child: Text('画像を表示できません'),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.center,
          child: imageWidget,
        ),
        RoundedSentence(sentence: sentence),
        Positioned(
          top: screenHeight * 0.08,
          right: 10,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white.withOpacity(0.5)),
            child: IconButton(
              iconSize: 35,
              icon: !storyViewModel.isVolume
                  ? const Icon(
                      Icons.volume_off,
                      color: Color.fromARGB(255, 255, 0, 0),
                    )
                  : storyViewModel.isVoiceDownloading
                      ? SizedBox(
                          width: screenWidth * 0.02,
                          height: screenWidth * 0.02,
                          child: const CircularProgressIndicator())
                      : const Icon(
                          Icons.volume_up,
                          color: Color.fromARGB(255, 26, 255, 0),
                        ),
              onPressed: () =>
                  storyViewModel.onVolumePressed(sentence: sentence),
            ),
          ),
        ),
      ],
    );
  }
}
