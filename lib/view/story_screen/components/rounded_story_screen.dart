//flutter
import 'package:flutter/material.dart';
//packages
import 'package:cached_network_image/cached_network_image.dart';
//components
import 'package:apapane/details/rounded_sentence.dart';
//models
import 'package:apapane/model/story_model.dart';

class RoundedStoryScreen extends StatelessWidget {
  const RoundedStoryScreen(
      {Key? key,
      required this.storyModel,
      required this.picture,
      required this.sentence})
      : super(key: key);
  final StoryModel storyModel;
  final String picture;
  final String sentence;
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            width: screenWidth * 1,
            height: screenHeight * 1,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                  image: CachedNetworkImageProvider(picture),
                  fit: BoxFit.cover),
            ),
          ),
        ),
        RoundedSentence(sentence: sentence),
        Positioned(
          top: screenHeight * 0.08, // 位置を調整してください
          right: 10, // 位置を調整してください
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white.withOpacity(0.5)),
            child: IconButton(
              iconSize: 35,
              icon: !storyModel.isVolume
                  ? const Icon(
                      Icons.volume_off,
                      color: Color.fromARGB(255, 255, 0, 0),
                    )
                  : storyModel.isVoiceDownloading
                      ? SizedBox(
                          width: screenWidth * 0.02,
                          height: screenWidth * 0.02,
                          child: const CircularProgressIndicator())
                      : const Icon(
                          Icons.volume_up,
                          color: Color.fromARGB(255, 26, 255, 0),
                        ),
              onPressed: () => storyModel.onVolumePressed(sentence: sentence),
            ),
          ),
        ),
      ],
    );
  }
}
